# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2015 John Vorhauer, Jens Wille                           #
#                                                                             #
# Lingo is free software; you can redistribute it and/or modify it under the  #
# terms of the GNU Affero General Public License as published by the Free     #
# Software Foundation; either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# Lingo is distributed in the hope that it will be useful, but WITHOUT ANY    #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for     #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with Lingo. If not, see <http://www.gnu.org/licenses/>.               #
#                                                                             #
###############################################################################
#++

require_relative 'database/progress'
require_relative 'database/crypter'
require_relative 'database/source'

class Lingo

  #--
  # Die Klasse Database stellt eine einheitliche Schnittstelle auf Lingo-Datenbanken bereit.
  # Die Identifizierung der Datenbank erfolgt über die ID der Datenbank, so wie sie in der
  # Sprachkonfigurationsdatei <tt>de.lang</tt> unter <tt>language/dictionary/databases</tt>
  # hinterlegt ist.
  #
  # Das Lesen und Schreiben der Datenbank erfolgt über die Funktionen []() und []=().
  #++

  class Database

    FLD_SEP = '|'
    KEY_REF = '*'
    SYS_KEY = '~'

    BACKENDS       = []
    BACKEND_BY_EXT = {}

    class << self

      def register(klass, ext, prio = -1, meth = true)
        BACKENDS.insert(prio, name = klass.name[/::(\w+)Store\z/, 1])
        Array(ext).each { |i| BACKEND_BY_EXT[i.insert(0, '.')] = name }

        klass.const_set(:EXT, ext)
        klass.class_eval('def store_ext; EXT; end', __FILE__, __LINE__) if meth
      end

      def open(*args, &block)
        new(*args).open(&block)
      end

    end

    def initialize(id, lingo)
      @id, @lingo, @config, @db = id, lingo, lingo.database_config(id), nil

      @val, @crypt, @srcfile = Hash.nest { [] }, config.key?('crypt'),
        Lingo.find(:dict, config['name'], relax: true)

      begin
        @stofile = Lingo.find(:store, @srcfile)
        FileUtils.mkdir_p(File.dirname(@stofile))
      rescue SourceFileNotFoundError => err
        @stofile = skip_ext = err.id
        backend = backend_from_file(@stofile) unless err.name
      rescue NoWritableStoreError
        backend = HashStore
      end

      use_backend(backend, skip_ext)

      convert unless uptodate?
    end

    attr_reader :lingo, :config, :backend

    def closed?
      !@db || _closed?
    end

    def open
      @db = _open if closed?
      block_given? ? yield(self) : self
    rescue => err
      raise DatabaseError.new(:open, @stofile, err)
    ensure
      close if @db && block_given?
    end

    def close
      _close unless closed?
      @db = nil

      self
    end

    def to_h
      hash = {}
      each { |key, val| hash[key.freeze] = val }
      hash
    end

    def each
      _each { |key, val| yield _encode!(key), _encode!(val) } unless closed?
    end

    def [](key)
      val = _val(key) unless closed?
      val.split(FLD_SEP) if val
    end

    def []=(key, val)
      return if closed?

      val = @val[key].concat(val)
      val.uniq!

      val = val.join(FLD_SEP)
      @crypt ? _set(*Crypter.encode(key, val)) : _set(key, val)
    end

    def warn(*msg)
      lingo.warn(*msg)
    end

    private

    def use_backend(backend = nil, skip_ext = false)
      [ENV['LINGO_BACKEND'], *BACKENDS].each { |mod|
        backend = get_backend(mod) and break if mod
      } unless backend

      extend(@backend = backend || HashStore)

      @stofile << store_ext if !skip_ext && respond_to?(:store_ext)
    end

    def get_backend(mod)
      self.class.const_get("#{mod}Store") if Object.const_defined?(mod)
    rescue TypeError, NameError
    end

    def backend_from_file(file)
      ext = File.extname(file)

      mod = BACKEND_BY_EXT[ext] or raise BackendNotFoundError.new(file)
      get_backend(mod) or raise BackendNotAvailableError.new(mod, file)
    end

    def config_hash
      hashes = [config]

      if use_lex = config['use-lex']
        hashes.concat(lingo.
          dictionary_config['databases'].
          values_at(*use_lex.split(SEP_RE)))
      end

      Crypter.digest(hashes.inspect)
    end

    def uptodate?(file = @stofile)
      src = Pathname.new(@srcfile)

      @source_key = lambda {
        [src.size, src.mtime, VERSION, config_hash].join(FLD_SEP)
      }

      sys_key = open { @db[SYS_KEY] } if File.exist?(file)
      sys_key && (!src.exist? || sys_key == @source_key.call)
    end

    def uptodate!
      @db[SYS_KEY] = @source_key.call
    end

    def create
      _clear
      open { yield }
    end

    def _clear
      File.delete(@stofile) if File.exist?(@stofile)
    end

    def _open
      raise NotImplementedError
    end

    def _close
      @db.close
    end

    def _closed?
      @db.closed?
    end

    def _each
      @db.each { |key, val| yield key, val }
    end

    def _set(key, val)
      @db[key] = val
    end

    def _get(key)
      @db[key]
    end

    def _val(key)
      if val = _get(@crypt ? Crypter.digest(key) : key)
        _encode!(val)
        @crypt ? Crypter.decode(key, val) : val
      end
    end

    def _encode!(str)
      str.force_encoding(ENC)
    end

    def convert(verbose = lingo.config.stderr.tty?)
      src = Source.get(config.fetch('txt-format', 'key_value'), @id, lingo)

      sep, key_map, val_map = prepare_lex

      Progress.new(self, src, verbose) { |progress| create {
        src.each { |key, val|
          progress << src.pos

          if key
            key.chomp!('.')

            if sep && key.include?(sep)
              key = key.split(sep).map!(&key_map).join(sep)
              val = val.map { |v| val_map[v.split(sep)].join(sep) } if val_map

              if (cnt = key.count(sep)) > 2
                self[key.split(sep)[0, 3].join(sep)] = ["#{KEY_REF}#{cnt + 1}"]
              end
            end
          end

          src.set(self, key, val)
        }

        uptodate!
      } }
    end

    def prepare_lex
      use_lex = config['use-lex'] or return

      args = [{
        'source' => use_lex.split(SEP_RE),
        'mode'   => config['lex-mode']
      }, lingo]

      dic = Language::Dictionary.new(*args)
      gra = Language::Grammar.new(*args)

      args = nil

      if inflect = config['inflect']
        inflect, wc = inflect == true ? %w[s e] : inflect.split(SEP_RE), 'a'

        if cfg = lingo.dictionary_config['inflect'] and suffixes = cfg[wc]
          wc, re = /#{wc}/, /\A[^#]+/
        else
          warn "#{self.class}: No suffixes to inflect ##{wc}: #{@id}"
          inflect = false
        end
      end

      [' ', lambda { |form|
        word = dic.find_word(form)

        if word.unknown?
          compo = gra.find_compound(form)

          if compo_form = compo.compo_form
            compo_form.form
          else
            compo.norm
          end
        else
          word.norm
        end
      }, inflect && lambda { |forms|
        inflectables = []

        forms.each { |form|
          word = dic.find_word(word_form = form[re])

          if word.identified? and lexical = word.get_class(wc).first
            inflectables << form if form == lexical.form
          else
            unless inflectables.empty?
              comp = gra.find_compound(word_form) if word.unknown?
              word = comp.head || comp if comp && !comp.unknown?

              if word.attr?(*inflect)
                suffix = suffixes[word.genders.compact.first]
                inflectables.each { |lex_form| lex_form << suffix } if suffix
              end
            end

            break
          end
        }

        forms
      }]
    end

  end

end

# in order of priority
require_relative 'database/libcdb_store'
require_relative 'database/sdbm_store'
require_relative 'database/gdbm_store'
require_relative 'database/hash_store'
