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

require 'sdbm'
require 'pathname'
require 'fileutils'
require 'digest/sha1'

%w[gdbm libcdb].each { |lib|
  next if ENV["LINGO_NO_#{lib.upcase}"]

  begin
    require lib
  rescue LoadError
  end
}

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

    include Cachable

    BACKENDS = %w[LibCDB SDBM GDBM].unshift(ENV['LINGO_BACKEND']).compact.uniq

    FLD_SEP = '|'
    IDX_REF = '^'
    KEY_REF = '*'
    SYS_KEY = '~'

    INDEX_PATTERN = %r{\A#{Regexp.escape(IDX_REF)}\d+\z}

    def self.open(*args, &block)
      new(*args).open(&block)
    end

    def initialize(id, lingo)
      @config = lingo.database_config(id)

      @id, @lingo = id, lingo
      @src_file   = Lingo.find(:dict, @config['name'])
      @crypter    = Crypter.new if @config.has_key?('crypt')

      begin
        @dbm_name = Lingo.find(:store, @src_file)
      rescue NoWritableStoreError
        @backend  = HashStore
      else
        FileUtils.mkdir_p(File.dirname(@dbm_name))
      end

      extend(backend)

      @dbm_name << store_ext if respond_to?(:store_ext, true)

      init_cachable
      convert unless uptodate?
    end

    def backend
      @backend ||= BACKENDS.find { |mod|
        break self.class.const_get("#{mod}Store") if Object.const_defined?(mod)
      } || HashStore
    end

    def closed?
      @db.nil? || _closed?
    end

    def open
      @db = _open if closed?
      block_given? ? yield(self) : self
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

      val = val.dup
      val.concat(retrieve(key)) if hit?(key)

      val.sort!
      val.uniq!
      store(key, val)

      val = val.join(FLD_SEP)
      key, val = @crypter.encode(key, val) if @crypter

      _set(key, val)
    end

    private

    def uptodate?(file = @dbm_name)
      src = Pathname.new(@src_file)
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
      File.delete(@dbm_name) if File.exist?(@dbm_name)
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

    def convert(verbose = @lingo.config.stderr.tty?)
      format = @config.fetch('txt-format', 'KeyValue').downcase
      source = Source.const_get(format.capitalize).new(@id, @lingo)

      if lex_dic = @config['use-lex']
        args = [{
          'source' => lex_dic.split(STRING_SEPARATOR_RE),
          'mode'   => @config['lex-mode']
        }, @lingo]

        dictionary, grammar = %w[Dictionary Grammar].map { |klass|
          Language.const_get(klass).new(*args)
        }
      end

      progress = ShowProgress.new(@config['name'], verbose, @lingo.config.stderr)
      progress.start('convert', source.size)

      create {
        index = -1

        source.each { |key, value|
          progress.tick(source.position)

          # Behandle Mehrwortschlüssel
          if lex_dic && key =~ / /
            # Schlüssel in Grundform wandeln
            gkey = key.split(' ').map { |form|
              # => Wortform ohne Satzendepunkt benutzen
              form.chomp!('.')

              result = dictionary.find_word(form)

              # => Kompositum suchen, wenn Wort nicht erkannt
              if result.attr == Language::WA_UNKNOWN
                result = grammar.find_compositum(form)
                compo  = result.compo_form
              end

              compo ? compo.form : result.norm
            }.join(' ')

            skey = gkey.split
            # Zusatzschlüssel einfügen, wenn Anzahl Wörter > 3
            self[skey[0, 3].join(' ')] = [KEY_REF + skey.size.to_s] if skey.size > 3

            key, value = gkey, value.map { |v| v.start_with?('#') ? key + v : v }
          end

          key.chomp!('.') if key

          case format
            when 'multivalue'
              self[key = "#{IDX_REF}#{index += 1}"] = value
              value.each { |v| self[v] = [key] }
            when 'multikey'
              value.each { |v| self[v] = [key] }
            else
              self[key] = value
          end
        }

        uptodate!
      }

      progress.stop('ok')
    end

    module HashStore

      def to_h
        @db.dup
      end

      def close
        self
      end

      private

      def uptodate?
        false
      end

      def uptodate!
        nil
      end

      def _clear
        @db.clear if @db
      end

      def _open
        {}
      end

      def _closed?
        false
      end

    end

    module SDBMStore

      private

      def uptodate?
        super(@dbm_name + '.pag')
      end

      def _clear
        File.delete(*Dir["#{@dbm_name}.{pag,dir}"])
      end

      def _open
        SDBM.open(@dbm_name)
      end

      def _set(key, val)
        if val.length > 950
          val = val[0, 950]

          @lingo.config.stderr.puts "Warning: Entry `#{key}' (#{@src_file})" <<
                                    'too long for SDBM. Truncating...'
        end

        super
      end

    end

    module GDBMStore

      private

      def store_ext
        '.db'
      end

      def _open
        GDBM.open(@dbm_name)
      end

    end

    module LibCDBStore

      private

      def store_ext
        '.cdb'
      end

      def create
        LibCDB::CDB.open(@dbm_name, 'w') { |db|
          @db = db
          yield
        }
      ensure
        @db = nil
      end

      def _open
        LibCDB::CDB.open(@dbm_name)
      end

    end

  end

end
