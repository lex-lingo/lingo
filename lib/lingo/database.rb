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

require 'pathname'
require 'fileutils'
require 'digest/sha1'

require_relative 'database/show_progress'
require_relative 'database/crypter'
require_relative 'database/source'
require_relative 'database/hash_store'
require_relative 'database/sdbm_store'
require_relative 'database/gdbm_store'
require_relative 'database/libcdb_store'

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
        FileUtils.mkdir_p(File.dirname(@dbm_name))
      rescue NoWritableStoreError
        @backend  = HashStore
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
      src = Source.get(@config.fetch('txt-format', 'KeyValue'), @id, @lingo)

      if lex = @config['use-lex']
        a, s = [{
          'source' => lex.split(STRING_SEPARATOR_RE),
          'mode'   => @config['lex-mode']
        }, @lingo], ' '

        dic = Language::Dictionary.new(*a)
        gra = Language::Grammar.new(*a)

        block = lambda { |form|
          res = dic.find_word(form)

          if res.unknown?
            res = gra.find_compositum(form)
            com = res.compo_form
          end

          com ? com.form : res.norm
        }
      end

      ShowProgress.new(self, src.size, verbose) { |progress| create {
        src.each { |key, val|
          progress[src.position]

          if key
            key.chomp!('.')

            if lex && key.include?(s)
              k = key.split(s).map!(&block).join(s)

              c = k.count(s) + 1
              self[k.split(s)[0, 3].join(s)] = ["#{KEY_REF}#{c}"] if c > 3

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
