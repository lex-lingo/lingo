# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2016 John Vorhauer, Jens Wille                           #
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

    KEY_REF_RE = %r{\A#{Regexp.escape(KEY_REF)}(\d+)\z}o

    BACKENDS       = []
    BACKEND_BY_EXT = {}

    class << self

      def register(klass, ext, prio = -1, meth = true)
        BACKENDS.insert(prio, name = klass.name[/::(\w+)Store\z/, 1])
        Array(ext).each { |i| BACKEND_BY_EXT[i.insert(0, '.')] = name }

        klass.const_set(:EXT, ext)
        klass.class_eval('def store_ext; EXT; end', __FILE__, __LINE__) if meth
      end

      def backend_by_ext(file, ext = File.extname(file))
        get_backend(BACKEND_BY_EXT[ext], file) or
          raise BackendNotFoundError.new(file)
      end

      def find_backend(env = 'LINGO_BACKEND')
        env && get_backend(ENV[env]) || BACKENDS.find { |name|
          backend = get_backend(name, nil, true) and return backend }
      end

      def get_backend(name, file = nil, relax = false)
        return unless name

        Object.const_get(name)
        const_get("#{name}Store")
      rescue TypeError, NameError => err
        raise BackendNotAvailableError.new(name, file, err) unless relax
      end

      def open(*args, &block)
        new(*args).open(&block)
      end

    end

    def initialize(id, lingo)
      @id, @lingo, @config, @db = id, lingo, lingo.database_config(id), nil

      @val, @crypt, @srcfile = Hash.array, config.key?('crypt'),
        Lingo.find(:dict, config['name'], relax: true)

      begin
        @stofile = Lingo.find(:store, @srcfile)
        FileUtils.mkdir_p(File.dirname(@stofile))
      rescue SourceFileNotFoundError => err
        @stofile = skip_ext = err.id
        backend = self.class.backend_by_ext(@stofile) unless err.name
      rescue NoWritableStoreError
        backend = HashStore
      end

      extend(@backend = backend || self.class.find_backend || HashStore)

      @stofile << store_ext unless skip_ext || !respond_to?(:store_ext)

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
      str.force_encoding(ENCODING)
    end

    def convert(verbose = lingo.config.stderr.tty?)
      src = Source.get(config.fetch('txt-format', 'key_value'), @id, lingo)

      sep, hyphenate, key_map, val_map = prepare_lex

      Progress.new(self, src, verbose) { |progress| create {
        src.each { |key, val|
          progress << src.pos

          set_key(src, key, val, sep) { |keys, cnt|
            key = keys.map!(&key_map).join(sep)
            val = val.map { |v| val_map[v.split(sep)].join(sep) } if val_map

            hyphenate.repeated_permutation(cnt - 1) { |h| set_key(src, keys.
              zip(h).join, val, sep) unless h.uniq.size == 1 } if hyphenate

            [key, val]
          }
        }

        uptodate!
      } }
    end

    def set_key(src, key, val, sep, len = 3)
      if key
        key.chomp!('.')

        if sep && key.include?(sep)
          keys = key.split(sep); cnt = keys.size
          key, val = yield keys, cnt if block_given?
          self[keys[0, len].join(sep)] = ["#{KEY_REF}#{cnt}"] if cnt > len
        end
      end

      src.set(self, key, val)
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

      wac = Language::WA_COMPOUND
      lac = Language::LA_COMPOUND

      if inflect = config['inflect']
        inflect, wc = inflect == true ? %w[s e] : inflect.split(SEP_RE), 'a'

        if cfg = lingo.dictionary_config['inflect'] and suffixes = cfg[wc]
          wc, re = /#{wc}/, /\A[^#]+/
        else
          warn "#{self.class}: No suffixes to inflect ##{wc}: #{@id}"
          inflect = false
        end
      end

      [sep = ' ', config['hyphenate'] && [sep, '-'], lambda { |form|
        word = dic.find_word(form)

        if word.unknown?
          comp = gra.find_compound(form)

          comp.attr == wac && comp.lex_form(lac) ||
            (comp.identified? ? comp.lex_form : comp.form)
        else
          word.identified? ? word.lex_form : word.form
        end
      }, inflect && lambda { |forms|
        inflectables = []

        forms.each { |form|
          word = dic.find_word(word_form = form[re])

          if word.identified? && _form = word.lex_form(wc)
            inflectables << form if form == _form
          else
            unless inflectables.empty?
              word = gra.find_compound_head(word_form) || word if word.unknown?

              if word.attr?(*inflect) && suffix =
                suffixes[word.genders.compact.first]
                inflectables.each { |lex_form| lex_form << suffix }
              end
            end

            break forms
          end
        }
      }]
    end

  end

end

# in order of priority
require_relative 'database/libcdb_store'
require_relative 'database/sdbm_store'
require_relative 'database/gdbm_store'
require_relative 'database/hash_store'
