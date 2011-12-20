# encoding: utf-8

#--
# LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
# Mehrworterkennung und Relationierung.
#
# Copyright (C) 2005-2007 John Vorhauer
# Copyright (C) 2007-2011 John Vorhauer, Jens Wille
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
require 'digest/sha1'

require_relative 'const'
require_relative 'types'
require_relative 'utilities'
require_relative 'modules'

class Lingo

  class ShowProgress

    def initialize(msg, active = true, out = $stderr)
      @active, @out, format = active, out, ' [%3d%%]'

      # To get the length of the formatted string we have
      # to actually substitute the place-holder(s).
      length = (format % 0).length

      # Now we know how far to "go back" to
      # overwrite the formatted string...
      back = "\b" * length

      @format = format       + back
      @clear  = ' ' * length + back

      print msg, ': '
    end

    def start(msg, max)
      @max, @count, @next_step = max, 0, 0
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
      percent = 100 * @count / @max
      @next_step = (percent + 1) * @max / 100

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
        #
        # NOTE: inject with each_slice(2) would be a natural fit,
        # but it's kind of slow...
        if first = !first
          q = HEX_CHARS.index(byte)
        else
          # Now we got both parts, so let's do the
          # inverse of divmod(16): q * 16 + r
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

    def TxtFile.filename(id, lingo)
      # Konfiguration der Datenbank auslesen
      config = lingo.config['language/dictionary/databases/' + id]
      raise "Es gibt in 'language/dictionary/databases' keine Datenbank mit der Kurzform '#{id}'" unless config && config.has_key?('name')

      # Pfade für Quelldatei und für ungültige Zeilen
      config['name']
    end

    def initialize(id, lingo)
      # Konfiguration der Datenbank auslesen
      @config = lingo.config['language/dictionary/databases/' + id]

      # Pfade für Quelldatei und für ungültige Zeilen
      @pn_source = Pathname.new(@config['name'])
      @pn_reject = Pathname.new(@config['name'].gsub(FILE_EXTENSION_PATTERN, '.rev'))

      Lingo.error("Quelldatei für id '#{id}' unter '" + @config['name'] + "' existiert nicht") unless @pn_source.exist?

      # Parameter standardisieren
      @wordclass = @config.fetch('def-wc', '?').downcase
      @separator = @config['separator']

      # Objektvariablen initialisieren
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
      reject_file = @pn_reject.open('w', :encoding => ENC)

      # Alle Zeilen der Quelldatei verarbeiten
      fail_msg = "Fehler beim öffnen der Wörterbuch-Quelldatei '#{@pn_source.to_s}'"

      @pn_source.each_line($/, :encoding => ENC) do |raw_line|
        @position += raw_line.size      # Position innerhalb der Datei aktualisieren
        line = raw_line.chomp.downcase  # Zeile normieren

        next if line =~ /^\s*\043/ || line.strip == ''  # Kommentarzeilen und leere Zeilen überspringen

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
      @line_pattern = Regexp.new('^(' + @legal_word + ')' + Regexp.escape(@separator) + '((?:' + @legal_word + '\043\w)+)$')
    end

    private

    def convert_line(line, key, val)
      key, valstr = key.strip, val.strip
      val = valstr.gsub(/\s+\043/, '#').scan(/\S.+?\s*\043\w/)
      val = val.map do |str|
        str =~ /^(.+)\043(.)/
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
  # Die Sonderbehandlung erfolgt in der Klasse Txt2DbmConverter, wo daraus Schlüssel-Werte-Paare in der Form
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

  # Die Klasse DbmFile stellt eine einheitliche Schnittstelle auf Lingo-Datenbanken bereit.
  # Die Identifizierung der Datenbank erfolgt über die ID der Datenbank, so wie sie in der
  # Sprachkonfigurationsdatei <tt>de.lang</tt> unter <tt>language/dictionary/databases</tt>
  # hinterlegt ist.
  #
  # Das Lesen und Schreiben der Datenbank erfolgt über die Funktionen []() und []=().

  class DbmFile

    include Cachable

    INDEX_PATTERN = %r{\A#{Regexp.escape(IDX_REF)}\d+\z}

    class << self

      # Erzeugt den Dateinamen des DbmFiles anhang der Konfiguration
      def filename(id, lingo)
        dir, name = File.split(TxtFile.filename(id, lingo))
        File.join(dir, 'store', name.sub(/\.txt\z/, ''))
      end

      def open(*args)
        dbm = new(*args)
        dbm.open { yield dbm }
      end

    end

    def initialize(id, lingo, read_mode = true)
      @lingo = lingo

      init_cachable

      @id, @dbm_name, @dbm = id, self.class.filename(id, lingo), nil

      # Aktualität prüfen
      Txt2DbmConverter.new(id, lingo).convert if read_mode && !uptodate?

      # Verschlüsselung vorbereiten
      @crypter = lingo.config["language/dictionary/databases/#{id}"].has_key?('crypt') ? Crypter.new : nil

      # Store-Ordner anlegen
      FileUtils.mkdir_p(File.dirname(@dbm_name))
    end

    # Überprüft die Aktualität des DbmFile
    def uptodate?
      begin
        source_key = open { @dbm[SYS_KEY] }
      rescue RuntimeError
      end if File.exist?("#{@dbm_name}.pag")

      # Dbm-Datei existiert nicht oder hat keinen Inhalt
      return false unless source_key

      # Mit Werten der Quelldatei vergleichen
      !(txt_file = Pathname.new(TxtFile.filename(@id, @lingo))).exist? ||
        source_key == "#{txt_file.size}#{FLD_SEP}#{txt_file.mtime}"
    end

    def open
      if closed?
        @dbm = SDBM.open(@dbm_name)
        block_given? ? yield : self
      else
        Lingo.error("DbmFile #{@dbm_name} bereits geöffnet")
      end
    ensure
      close if @dbm && block_given?
    end

    def to_h
      hash = {}

      @dbm.each { |key, val|
        [key, val].each { |x| x.encode!(ENC) }
        hash[key.freeze] = val
      } unless closed?

      hash
    end

    def clear
      files = %w[pag dir].map { |ext| "#{@dbm_name}.#{ext}" }

      if closed?
        files.each { |file| File.delete(file) if File.exist?(file) }
      else
        close
        files.each { |file| File.delete(file) }
        open
      end

      self
    end

    def close
      unless closed?
        @dbm.close
        @dbm = nil

        self
      else
        #Lingo.error("DbmFile #{@dbm_name} nicht geöffnet")
      end
    end

    def closed?
      @dbm.nil? || @dbm.closed?
    end

    def [](key)
      return if closed?

      if val = _get(key)
        # Äquvalenzklassen behandeln
        val.split(FLD_SEP).map { |v|
          v =~ INDEX_PATTERN ? _get(v) : v
        }.compact.join(FLD_SEP).split(FLD_SEP)
      end
    end

    def []=(key, val)
      return if closed?

      val += retrieve(key) if hit?(key)

      store(key, val = val.sort.uniq)
      _set(key, val.join(FLD_SEP))
    end

    def set_source_file(filename)
      return if closed?

      src = Pathname.new(filename.downcase)
      @dbm[SYS_KEY] = [src.size, src.mtime].join(FLD_SEP)
    end

    private

    def _get(key)
      if val = @dbm[@crypter ? @crypter.digest(key) : key]
        val.encode!(ENC)
        @crypter ? @crypter.decode(key, val) : val
      end
    end

    def _set(key, val)
      key, val = @crypter.encode(key, val) if @crypter
      @dbm[key] = (val.length < 950) ? val : val[0, 950]
    end

  end

  # Die Klasse Txt2DbConverter steuert die Konvertierung von Wörterbuch-Quelldateien in
  # Lingo-Datenbanken. Die Identifizierung der Quelldatei erfolgt über die ID
  # der Datei, so wie sie in der Sprachkonfigurationsdatei <tt>de.lang</tt> unter
  # <tt>language/dictionary/databases</tt> hinterlegt ist.

  class Txt2DbmConverter

    def initialize(id, lingo, verbose = true)
      # Konfiguration der Datenbanken auslesen
      @config = lingo.config['language/dictionary/databases/' + id]
      @index = 0

      # Objekt für Quelldatei erzeugen
      @format = @config.fetch( 'txt-format', 'KeyValue' ).downcase
      @source = case @format
        when 'singleword' then TxtFile_Singleword
        when 'keyvalue'   then TxtFile_Keyvalue
        when 'wordclass'  then TxtFile_Wordclass
        when 'multivalue' then TxtFile_Multivalue
        when 'multikey'   then TxtFile_Multikey
        else
          Lingo.error("Unbekanntes Textformat '#{config['txt-format'].downcase}' bei '#{'language/dictionary/databases/' + id}'")
      end.new(id, lingo)

      # Zielobjekt erzeugen
      @destination = DbmFile.new(id, lingo, false)

      # Ausgabesteuerung
      @progress = ShowProgress.new(@config['name'], verbose, lingo.config.stderr)

      # Lexikalisierungen für Mehrwortgruppen vorbereiten
      lex_dic = @config['use-lex']
      lex_mod = @config['lex-mode']

      begin
        @lexicalize = true
        @dictionary = Dictionary.new({ 'source' => lex_dic.split(STRING_SEPERATOR_PATTERN), 'mode' => lex_mod }, lingo)
        @grammar = Grammar.new({ 'source' => lex_dic.split(STRING_SEPERATOR_PATTERN), 'mode' => lex_mod }, lingo)
      rescue RuntimeError
        Lingo.error("Auf das Wörterbuch (#{lex_dic}) für die Lexikalisierung der Mehrwortgruppen in (#{@config['name']}) konnte nicht zugegriffen werden")
      end if lex_dic
    end

    def convert
      @progress.start('convert', @source.size)

      @destination.open
      @destination.clear

      @source.each do |key, value|
        @progress.tick(@source.position)

        # Behandle Mehrwortschlüssel
        if @lexicalize && key =~ / /
          # Schlüssel in Grundform wandeln
          gkey = key.split(' ').map do |form|

            # => Wortform ohne Satzendepunkt benutzen
            wordform = form.gsub(/\.$/, '')

            # => Wort suchen
            result = @dictionary.find_word(wordform)

            # => Kompositum suchen, wenn Wort nicht erkannt
            if result.attr == WA_UNKNOWN
              result = @grammar.find_compositum(wordform)
              compo = result.compo_form
            end

            compo ? compo.form : result.norm
          end.join(' ')

          skey = gkey.split
          # Zusatzschlüssel einfügen, wenn Anzahl Wörter > 3
          @destination[skey[0...3].join(' ')] = [KEY_REF + skey.size.to_s] if skey.size > 3

          value = value.map { |v| v =~ /^\043/ ? key + v : v }
          key = gkey
        end

        # Format Sonderbehandlungen
        key.gsub!(/\.$/, '') if key
        case @format
        when 'multivalue'    # Äquvalenzklassen behandeln
          key = IDX_REF + @index.to_s
          @index += 1
          @destination[key] = value
          value.each { |v| @destination[v] = [key] }
        when 'multikey'      # Äquvalenzklassen behandeln
          value.each { |v| @destination[v] = [key] }
        else
          @destination[key] = value
        end

      end

      @destination.set_source_file(@config['name'])
      @destination.close

      @progress.stop('ok')

      self
    end

  end

end
