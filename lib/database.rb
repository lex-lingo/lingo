# encoding: utf-8

#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005-2007 John Vorhauer
#  Copyright (C) 2007-2011 John Vorhauer, Jens Wille
#
#  This program is free software; you can redistribute it and/or modify it under
#  the terms of the GNU Affero General Public License as published by the Free
#  Software Foundation; either version 3 of the License, or (at your option)
#  any later version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
#  details.
#
#  You should have received a copy of the GNU Affero General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
#  For more information visit http://www.lex-lingo.de or contact me at
#  welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
#  Lex Lingo rules from here on

require 'sdbm'
require 'digest/sha1'
require './lib/const'
require './lib/types'
require './lib/utilities'
require './lib/modules'

# ShowPercent ermöglicht die Fortschrittsanzeige beim konvertieren der
# Wörterbücher

class ShowPercent

  def initialize(verbose = true)
    @verbose = verbose

    format = ' [%3d%%]'

    # To get the length of the formatted string we have
    # to actually substitute the place-holder(s).
    length = (format % 0).length

    # Now we know how far to "go back" to
    # overwrite the formatted string...
    back = "\b" * length

    @format = format       + back
    @clear  = ' ' * length + back
  end

  def start(max)
    @max, @count, @next_step = max, 0, 0
    show
  end

  def stop
    print @clear
  end

  def inc(increment)
    @count += increment
    show if show?
  end

  def set(absolute)
    @count = absolute
    show if show?
  end

  def show
    percent = 100 * @count / @max
    @next_step = (percent + 1) * @max / 100

    print @format % percent if @verbose
  end

  def show?
    @count >= @next_step
  end

end

# Crypter ermöglicht die Ver- und Entschlüsselung von Wörterbüchern

class Crypter

  def digest(key)
    Digest::SHA1.hexdigest(key)
  end


  def encode(key, val)
    [Digest::SHA1.hexdigest(key), crypt(key, val).to_x]
  end


  def decode(key, val)
    crypt(key, val.from_x)
  end

  private

if ISITRUBY19
  def crypt(k, v)
    c, i = '-' * v.size, k.size
    (0...c.size).each { |j|
      i -= 1
      c[j] = (v[j].ord ^ k[i].ord).chr
      i = k.size if i == 0
    }
    c
  end
else
  def crypt(k, v)
    c = '-' * v.size
    i = k.size
    (0...c.size).each { |j|
      i-=1
      c[j]=v[j]^k[i]
      i==0 && i=k.size
    }
    c
  end
end

end

# == TxtFile
#
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

  def TxtFile.filename(id)
    #  Konfiguration der Datenbank auslesen
    config = Lingo.config['language/dictionary/databases/' + id]
    raise "Es gibt in 'language/dictionary/databases' keine Datenbank mit der Kurzform '#{id}'" unless config && config.has_key?('name')

    #  Pfade für Quelldatei und für ungültige Zeilen
    config['name']
  end

  def initialize(id)
    #  Konfiguration der Datenbank auslesen
    @config = Lingo.config['language/dictionary/databases/' + id]

    #  Pfade für Quelldatei und für ungültige Zeilen
    @pn_source = Pathname.new(@config['name'])
    @pn_reject = Pathname.new(@config['name'].gsub(FILE_EXTENSION_PATTERN, '.rev'))

    Lingo.error("Quelldatei für id '#{id}' unter '" + @config['name'] + "' existiert nicht") unless @pn_source.exist?

    #  Parameter standardisieren
    @wordclass = @config.fetch('def-wc', '?').downcase
    @separator = @config['separator']

    #  Objektvariablen initialisieren
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

      #  Ungültige Zeilen protokollieren
      unless line.length < 4096 && line =~ @line_pattern
        fail_msg = "Fehler beim schreiben der Reject-Datei '#{@pn_reject.to_s}'"
        reject_file.puts line
        next
      end

      #  Zeile in Werte konvertieren
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

# == TxtFile_Singleword
#
# Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>SingleWord</tt>.
# Eine Zeile <tt>"Fachbegriff\n"</tt> wird gewandelt in <tt>[ 'fachbegriff', ['#s'] ]</tt>.
# Die Wortklasse kann über den Parameter <tt>def-wc</tt> beeinflusst werden.

class TxtFile_Singleword < TxtFile

  def initialize(id)
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

# == TxtFile_Keyvalue
#
# Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>KeyValue</tt>.
# Eine Zeile <tt>"Fachbegriff*Fachterminus\n"</tt> wird gewandelt in <tt>[ 'fachbegriff', ['fachterminus#s'] ]</tt>.
# Die Wortklasse kann über den Parameter <tt>def-wc</tt> beeinflusst werden.
# Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

class TxtFile_Keyvalue < TxtFile

  def initialize(id)
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

# == TxtFile_Wordclass
#
# Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>WordClass</tt>.
# Eine Zeile <tt>"essen,essen #v essen #o esse #s\n"</tt> wird gewandelt in <tt>[ 'essen', ['esse#s', 'essen#v', 'essen#o'] ]</tt>.
# Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

class TxtFile_Wordclass < TxtFile

  def initialize(id)
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

# == TxtFile_Multivalue
#
# Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>MultiValue</tt>.
# Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ nil, ['triumph', 'sieg', 'erfolg'] ]</tt>.
# Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

class TxtFile_Multivalue < TxtFile

  def initialize(id)
    super

    @separator = @config.fetch('separator', ';')
    @line_pattern = Regexp.new('^' + @legal_word + '(?:' + Regexp.escape(@separator) + @legal_word + ')*$')
  end

  private

  def convert_line(line, key, val)
    [nil, line.split(@separator).map { |value| value.strip }]
  end

end

# == TxtFile_Multikey
#
# Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>MultiKey</tt>.
# Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ 'triumph', ['sieg', 'erfolg'] ]</tt>.
# Die Sonderbehandlung erfolgt in der Klasse Txt2DbmConverter, wo daraus Schlüssel-Werte-Paare in der Form
# <tt>[ 'sieg', ['triumph'] ]</tt> und <tt>[ 'erfolg', ['triumph'] ]</tt> erzeugt werden.
# Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

class TxtFile_Multikey < TxtFile

  def initialize(id)
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

# == DbmFile
#
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
    def filename(id)
      dir, name = File.split(TxtFile.filename(id))
      File.join(dir, 'store', name.sub(/\.txt\z/, ''))
    end

    def open(*args)
      dbm = new(*args)
      dbm.open { yield dbm }
    end

  end

  def initialize(id, read_mode = true)
    init_cachable

    @id, @dbm_name, @dbm = id, self.class.filename(id), nil

    # Aktualität prüfen
    Txt2DbmConverter.new(id).convert if read_mode && !uptodate?

    # Verschlüsselung vorbereiten
    @crypter = Lingo.config["language/dictionary/databases/#{id}"].has_key?('crypt') ? Crypter.new : nil

    # Store-Ordner anlegen
    Pathname.new(@dbm_name).create_path
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
    !(txt_file = Pathname.new(TxtFile.filename(@id))).exist? ||
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

# == Txt2DbConverter
#
# Die Klasse Txt2DbConverter steuert die Konvertierung von Wörterbuch-Quelldateien in
# Lingo-Datenbanken. Die Identifizierung der Quelldatei erfolgt über die ID
# der Datei, so wie sie in der Sprachkonfigurationsdatei <tt>de.lang</tt> unter
# <tt>language/dictionary/databases</tt> hinterlegt ist.

class Txt2DbmConverter

  def initialize(id, verbose = true)
    #  Konfiguration der Datenbanken auslesen
    @config = Lingo::config['language/dictionary/databases/' + id]
    @index = 0

    #  Objekt für Quelldatei erzeugen
    @format = @config.fetch( 'txt-format', 'KeyValue' ).downcase
    @source = case @format
      when 'singleword' then TxtFile_Singleword
      when 'keyvalue'   then TxtFile_Keyvalue
      when 'wordclass'  then TxtFile_Wordclass
      when 'multivalue' then TxtFile_Multivalue
      when 'multikey'   then TxtFile_Multikey
      else
        Lingo.error("Unbekanntes Textformat '#{config['txt-format'].downcase}' bei '#{'language/dictionary/databases/' + id}'")
    end.new(id)

    #  Zielobjekt erzeugen
    @destination = DbmFile.new(id, false)

    #    Ausgabesteuerung
    if @verbose = verbose
      @perc = ShowPercent.new(@verbose)
      print @config['name'], ': '
    end

    #  Lexikalisierungen für Mehrwortgruppen vorbereiten
    lex_dic = @config['use-lex']
    lex_mod = @config['lex-mode']

    begin
      @lexicalize = true
      @dictionary = Dictionary.new({ 'source' => lex_dic.split(STRING_SEPERATOR_PATTERN), 'mode' => lex_mod }, Lingo::config['language/dictionary'])
      @grammar = Grammar.new({ 'source' => lex_dic.split(STRING_SEPERATOR_PATTERN), 'mode' => lex_mod }, Lingo::config['language/dictionary'])
    rescue RuntimeError
      Lingo.error("Auf das Wörterbuch (#{lex_dic}) für die Lexikalisierung der Mehrwortgruppen in (#{@config['name']}) konnte nicht zugegriffen werden")
    end if lex_dic
  end

  def convert
    if @verbose
      print 'convert '
      @perc.start(@source.size)
    end

    @destination.open
    @destination.clear

    @source.each do |key, value|
      @perc.set(@source.position) if @verbose        #  Status ausgeben

      #  Behandle Mehrwortschlüssel
      if @lexicalize && key =~ / /
        #  Schlüssel in Grundform wandeln
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
        #  Zusatzschlüssel einfügen, wenn Anzahl Wörter > 3
        @destination[skey[0...3].join(' ')] = [KEY_REF + skey.size.to_s] if skey.size > 3

        value = value.map { |v| v =~ /^\043/ ? key + v : v }
        key = gkey
      end

      #  Format Sonderbehandlungen
      key.gsub!(/\.$/, '') if key
      case @format
      when 'multivalue'    #  Äquvalenzklassen behandeln
        key = IDX_REF + @index.to_s
        @index += 1
        @destination[key] = value
        value.each { |v| @destination[v] = [key] }
      when 'multikey'      #  Äquvalenzklassen behandeln
        value.each { |v| @destination[v] = [key] }
      else
        @destination[key] = value
      end

    end
    @destination.set_source_file(@config['name'])

    @destination.close

    if @verbose
      @perc.stop
      puts 'ok '
    end

    self
  end

end
