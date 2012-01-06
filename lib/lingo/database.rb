# encoding: utf-8

#--
# LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
# Mehrworterkennung und Relationierung.
#
# Copyright (C) 2005-2007 John Vorhauer
# Copyright (C) 2007-2012 John Vorhauer, Jens Wille
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
# For more information visit http://www.lex-lingo.de or contact me at
# welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
# Lex Lingo rules from here on
#++

require 'sdbm'
require 'pathname'
require 'fileutils'
require 'digest/sha1'

[%w[gdbm], %w[cdb cdb-full]].each { |l, g|
  next if ENV["LINGO_NO_#{l.upcase}"]

  begin
    gem g if g
    require l
  rescue LoadError
  end
}

require_relative 'const'
require_relative 'types'
require_relative 'utilities'
require_relative 'modules'

class Lingo

  class ShowProgress

    def initialize(msg, active = true, out = $stderr)
      @active, @out, format = active, out, ' [%3d%%]'

      # To get the length of the formatted string we have
      # to actually substitute the placeholder.
      length = (format % 0).length

      # Now we know how far to "go back" to
      # overwrite the formatted string...
      back = "\b" * length

      @format = format       + back
      @clear  = ' ' * length + back

      print msg, ': '
    end

    def start(msg, max)
      @ratio, @count, @next_step = max / 100.0, 0, 0
      print msg, ' '
      step
    end

    def stop(msg)
      print @clear
      print msg, "\n"
    end

    def tick(value)
      @count = value
      step if @count >= @next_step
    end

    private

    def step
      percent = @count / @ratio
      @next_step = (percent + 1) * @ratio

      print @format % percent
    end

    def print(*args)
      @out.print(*args) if @active
    end

  end

  # Crypter ermöglicht die Ver- und Entschlüsselung von Wörterbüchern

  class Crypter

    HEX_CHARS = '0123456789abcdef'.freeze

    def digest(key)
      Digest::SHA1.hexdigest(key)
    end

    def encode(key, val)
      hex = ''

      crypt(key, val).each_byte { |byte|
        # To get a hex representation for a char we just utilize
        # the quotient and the remainder of division by base 16.
        q, r = byte.divmod(16)
        hex << HEX_CHARS[q] << HEX_CHARS[r]
      }

      [digest(key), hex]
    end

    def decode(key, val)
      str, q, first = '', 0, false

      val.each_byte { |byte|
        byte = byte.chr(ENC)

        # Our hex chars are 2 bytes wide, so we have to keep track
        # of whether it's the first or the second of the two.
        if first = !first
          q = HEX_CHARS.index(byte)
        else
          # Now we got both parts, so let's revert the divmod(16)
          str << q * 16 + HEX_CHARS.index(byte)
        end
      }

      crypt(key, str)
    end

    private

    def crypt(k, v)
      c, y = '', k.codepoints.reverse_each.cycle
      v.each_codepoint { |x| c << (x ^ y.next).chr(ENC) }
      c
    end

  end

  # Die Klasse TxtFile stellt eine einheitliche Schnittstelle auf die unterschiedlichen Formate
  # von Wörterbuch-Quelldateien bereit. Die Identifizierung der Quelldatei erfolgt über die ID
  # der Datei, so wie sie in der Sprachkonfigurationsdatei <tt>de.lang</tt> unter
  # <tt>language/dictionary/databases</tt> hinterlegt ist.
  #
  # Die Verarbeitung der Wörterbücher erfolgt mittels des Iterators <b>each</b>, der für jede
  # Zeile der Quelldatei ein Array bereitstellt in der Form <tt>[ key, [val1, val2, ...] ]</tt>.
  #
  # Nicht korrekt erkannte Zeilen werden abgewiesen und in eine Revoke-Datei gespeichert, die
  # an der Dateiendung <tt>.rev</tt> zu erkennen ist.

  class TxtFile

    attr_reader :position

    def initialize(id, lingo)
      # Konfiguration der Datenbank auslesen
      @config = lingo.database_config(id)

      source_file = Lingo.find(:dict, name = @config['name'])

      @pn_source = Pathname.new(source_file)
      @pn_reject = Pathname.new(Lingo.find(:store, source_file) << '.rev')

      Lingo.error("No such source file `#{name}' for `#{id}'.") unless @pn_source.exist?

      @wordclass = @config.fetch('def-wc', '?').downcase
      @separator = @config['separator']

      @legal_word = '(?:' + PRINTABLE_CHAR + '|[' + Regexp.escape('- /&()[].,') + '])+'  # TODO: v1.60 - ',' bei TxtFile zulassen; in const.rb einbauen
      @line_pattern = Regexp.new('^'+@legal_word+'$')

      @position = 0
    end

    def size
      @pn_source.size
    end

    def each
      # Reject-Datei öffnen
      fail_msg = "Fehler beim öffnen der Reject-Datei '#{@pn_reject.to_s}'"
      reject_file = @pn_reject.open('w', encoding: ENC)

      # Alle Zeilen der Quelldatei verarbeiten
      fail_msg = "Fehler beim öffnen der Wörterbuch-Quelldatei '#{@pn_source.to_s}'"

      @pn_source.each_line($/, encoding: ENC) do |raw_line|
        @position += raw_line.size      # Position innerhalb der Datei aktualisieren
        line = raw_line.chomp.downcase  # Zeile normieren

        next if line =~ /^\s*#/ || line.strip == ''  # Kommentarzeilen und leere Zeilen überspringen

        # Ungültige Zeilen protokollieren
        unless line.length < 4096 && line =~ @line_pattern
          fail_msg = "Fehler beim schreiben der Reject-Datei '#{@pn_reject.to_s}'"
          reject_file.puts line
          next
        end

        # Zeile in Werte konvertieren
        yield convert_line(line, $1, $2)
      end

      fail_msg = "Fehler beim Schließen der Reject-Datei '#{@pn_reject.to_s}'"
      reject_file.close
      @pn_reject.delete if @pn_reject.size == 0

      self
    rescue RuntimeError
      Lingo.error(fail_msg)
    end

  end

  # Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>SingleWord</tt>.
  # Eine Zeile <tt>"Fachbegriff\n"</tt> wird gewandelt in <tt>[ 'fachbegriff', ['#s'] ]</tt>.
  # Die Wortklasse kann über den Parameter <tt>def-wc</tt> beeinflusst werden.

  class TxtFile_Singleword < TxtFile

    def initialize(id, lingo)
      super

      @wc     = @config.fetch('def-wc',     's').downcase
      @mul_wc = @config.fetch('def-mul-wc', @wc).downcase

      @line_pattern = %r{^(#{@legal_word})$}
    end

    private

    def convert_line(line, key, val)
      [key = key.strip, %W[##{key =~ /\s/ ? @mul_wc : @wc}]]
    end

  end

  # Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>KeyValue</tt>.
  # Eine Zeile <tt>"Fachbegriff*Fachterminus\n"</tt> wird gewandelt in <tt>[ 'fachbegriff', ['fachterminus#s'] ]</tt>.
  # Die Wortklasse kann über den Parameter <tt>def-wc</tt> beeinflusst werden.
  # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

  class TxtFile_Keyvalue < TxtFile

    def initialize(id, lingo)
      super

      @separator = @config.fetch('separator', '*')
      @line_pattern = Regexp.new('^(' + @legal_word + ')' + Regexp.escape(@separator) + '(' + @legal_word + ')$')
    end

    private

    def convert_line(line, key, val)
      key, val = key.strip, val.strip
      val = '' if key == val
      val = [val + '#' + @wordclass]
      [key, val]
    end

  end

  # Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>WordClass</tt>.
  # Eine Zeile <tt>"essen,essen #v essen #o esse #s\n"</tt> wird gewandelt in <tt>[ 'essen', ['esse#s', 'essen#v', 'essen#o'] ]</tt>.
  # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

  class TxtFile_Wordclass < TxtFile

    def initialize(id, lingo)
      super

      @separator = @config.fetch('separator', ',')
      @line_pattern = Regexp.new('^(' + @legal_word + ')' + Regexp.escape(@separator) + '((?:' + @legal_word + '#\w)+)$')
    end

    private

    def convert_line(line, key, val)
      key, valstr = key.strip, val.strip
      val = valstr.gsub(/\s+#/, '#').scan(/\S.+?\s*#\w/)
      val = val.map do |str|
        str =~ /^(.+)#(.)/
        ($1 == key ? '' : $1) + '#' + $2
      end
      [key, val]
    end

  end

  # Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>MultiValue</tt>.
  # Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ nil, ['triumph', 'sieg', 'erfolg'] ]</tt>.
  # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

  class TxtFile_Multivalue < TxtFile

    def initialize(id, lingo)
      super

      @separator = @config.fetch('separator', ';')
      @line_pattern = Regexp.new('^' + @legal_word + '(?:' + Regexp.escape(@separator) + @legal_word + ')*$')
    end

    private

    def convert_line(line, key, val)
      [nil, line.split(@separator).map { |value| value.strip }]
    end

  end

  # Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>MultiKey</tt>.
  # Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ 'triumph', ['sieg', 'erfolg'] ]</tt>.
  # Die Sonderbehandlung erfolgt in der Methode Database#convert, wo daraus Schlüssel-Werte-Paare in der Form
  # <tt>[ 'sieg', ['triumph'] ]</tt> und <tt>[ 'erfolg', ['triumph'] ]</tt> erzeugt werden.
  # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

  class TxtFile_Multikey < TxtFile

    def initialize(id, lingo)
      super

      @separator = @config.fetch('separator', ';')
      @line_pattern = Regexp.new('^' + @legal_word + '(?:' + Regexp.escape(@separator) + @legal_word + ')*$')
    end

    private

    def convert_line(line, key, val)
      values = line.split(@separator).map { |value| value.strip }
      [values[0], values[1..-1]]
    end

  end

  # Die Klasse Database stellt eine einheitliche Schnittstelle auf Lingo-Datenbanken bereit.
  # Die Identifizierung der Datenbank erfolgt über die ID der Datenbank, so wie sie in der
  # Sprachkonfigurationsdatei <tt>de.lang</tt> unter <tt>language/dictionary/databases</tt>
  # hinterlegt ist.
  #
  # Das Lesen und Schreiben der Datenbank erfolgt über die Funktionen []() und []=().

  class Database

    include Cachable

    INDEX_PATTERN = %r{\A#{Regexp.escape(IDX_REF)}\d+\z}

    def self.open(*args, &block)
      new(*args).open(&block)
    end

    def initialize(id, lingo)
      @config = lingo.database_config(id)
      raise "No such database `#{id}'." unless @config && @config.has_key?('name')

      @id, @lingo = id, lingo
      @crypter    = Crypter.new if @config.has_key?('crypt')

      # @db: closed?, close, each, [], []=
      extend(Object.const_defined?(:CDB)  ? CDB  :
             Object.const_defined?(:GDBM) ? GDBM : SDBM)

      init
      init_cachable
      convert unless uptodate?
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

    def init
      @src_file = Lingo.find(:dict, @config['name'])
      @dbm_name = Lingo.find(:store, @src_file)
      FileUtils.mkdir_p(File.dirname(@dbm_name))
    end

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
      open { |db| yield db }
    end

    def _clear
      File.delete(@dbm_name) if File.exist?(@dbm_name)
    end

    def _open
      raise NotImplementedError
    end

    def _close
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
      source = Lingo.const_get("TxtFile_#{format.capitalize}").new(@id, @lingo)

      if lex_dic = @config['use-lex']
        args = [{
          'source' => lex_dic.split(STRING_SEPERATOR_PATTERN),
          'mode'   => @config['lex-mode']
        }, @lingo]

        dictionary, grammar = Dictionary.new(*args), Grammar.new(*args)
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
              if result.attr == WA_UNKNOWN
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

    module SDBM

      private

      def uptodate?
        super(@dbm_name + '.pag')
      end

      def _clear
        File.delete(*Dir["#{@dbm_name}.{pag,dir}"])
      end

      def _open
        ::SDBM.open(@dbm_name)
      end

      def _set(key, val)
        super(key, val.length < 950 ? val : val[0, 950])
      end

    end

    module GDBM

      private

      def init
        super
        @dbm_name << '.db'
      end

      def _open
        ::GDBM.open(@dbm_name)
      end

    end

    module CDB

      def close
        super.tap { @closed = true }
      end

      private

      def _closed?
        @closed
      end

      def init
        super
        @dbm_name << '.cdb'
      end

      def create
        ::CDBMake.open(@dbm_name) { |db|
          @db = db
          yield
          @db = nil
        }
      end

      def _open
        ::CDB.new(@dbm_name).tap { @closed = false }
      end

      def _get(key)
        res = nil; @db.each(key) { |val| res = val }; res
      end

    end

  end

end
