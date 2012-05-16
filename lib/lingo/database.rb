# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2012 John Vorhauer, Jens Wille                           #
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

require_relative 'database/show_progress'
require_relative 'database/crypter'
require_relative 'database/source'

class Lingo

  # Die Klasse Database stellt eine einheitliche Schnittstelle auf Lingo-Datenbanken bereit.
  # Die Identifizierung der Datenbank erfolgt über die ID der Datenbank, so wie sie in der
  # Sprachkonfigurationsdatei <tt>de.lang</tt> unter <tt>language/dictionary/databases</tt>
  # hinterlegt ist.
  #
  # Das Lesen und Schreiben der Datenbank erfolgt über die Funktionen []() und []=().

  class Database

    FLD_SEP = '|'
    IDX_REF = '^'
    KEY_REF = '*'
    SYS_KEY = '~'

    IDX_REF_ESC = Regexp.escape(IDX_REF)
    KEY_REF_ESC = Regexp.escape(KEY_REF)

    INDEX_PATTERN = %r{\A#{IDX_REF_ESC}\d+\z}

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

    attr_reader :backend

    def initialize(id, lingo)
      @id, @lingo, @config, @db = id, lingo, lingo.database_config(id), nil

      @srcfile = Lingo.find(:dict, @config['name'], relax: true)
      @crypter = @config.has_key?('crypt') && Crypter.new

      @val = Hash.new { |h, k| h[k] = [] }

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

    def closed?
      @db.nil? || _closed?
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
      @db.close unless closed?
      @db = nil

      self
    end

    def to_h
      {}.tap { |hash| @db.each { |key, val|
        hash[key.force_encoding(ENC).freeze] = val.force_encoding(ENC)
      } unless closed? }
    end

    def [](key)
      val = _val(key) unless closed?
      return unless val

      # Äquvalenzklassen behandeln
      val.split(FLD_SEP).map { |v|
        v =~ INDEX_PATTERN ? _val(v) : v
      }.compact.join(FLD_SEP).split(FLD_SEP)
    end

    def []=(key, val)
      return if closed?

      arg = [key, @val[key].concat(val).sort!.tap(&:uniq!).join(FLD_SEP)]
      _set(*@crypter ? @crypter.encode(*arg) : arg)
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

    def uptodate?(file = @stofile)
      src = Pathname.new(@srcfile)
      @source_key = lambda { [src.size, src.mtime].join(FLD_SEP) }

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

    def _closed?
      @db.closed?
    end

    def _set(key, val)
      @db[key] = val
    end

    def _get(key)
      @db[key]
    end

    def _val(key)
      if val = _get(@crypter ? @crypter.digest(key) : key)
        val.force_encoding(ENC)
        @crypter ? @crypter.decode(key, val) : val
      end
    end

    def warn(*msg)
      @lingo.warn(*msg)
    end

    def convert(verbose = @lingo.config.stderr.tty?)
      src = Source.get(@config.fetch('txt-format', 'key_value'), @id, @lingo)

      if lex = @config['use-lex']
        a = [{ 'source' => lex.split(SEP_RE), 'mode' => @config['lex-mode'] }, @lingo]
        d, g = Language::Dictionary.new(*a), Language::Grammar.new(*a); a = nil

        sep, block = ' ', lambda { |f|
          (r = d.find_word(f)).unknown? &&
            (c = (r = g.find_compound(f)).compo_form) ? c.form : r.norm
        }
      end

      ShowProgress.new(self, src.size, verbose) { |progress| create {
        src.each { |key, val|
          progress[src.pos]

          if key
            key.chomp!('.')

            if lex && key.include?(sep)
              k = key.split(sep).map!(&block).join(sep)

              c = k.count(sep) + 1
              self[k.split(sep)[0, 3].join(sep)] = ["#{KEY_REF}#{c}"] if c > 3

              key, val = k, val.map { |v| v.start_with?('#') ? key + v : v }
            end
          end

          src.set(self, key, val)
        }

        uptodate!
      } }
    end

  end

end

# in order of priority
require_relative 'database/libcdb_store'
require_relative 'database/sdbm_store'
require_relative 'database/gdbm_store'
require_relative 'database/hash_store'
