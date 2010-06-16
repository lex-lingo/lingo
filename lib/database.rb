# encoding: utf-8

#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung, 
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005  John Vorhauer
#
#  This program is free software; you can redistribute it and/or modify it under 
#  the terms of the GNU General Public License as published by the Free Software 
#  Foundation;  either version 2 of the License, or  (at your option)  any later
#  version.
#
#  This program is distributed  in the hope  that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
#  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#  You should have received a copy of the  GNU General Public License along with 
#  this program; if not, write to the Free Software Foundation, Inc., 
#  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
#  For more information visit http://www.lex-lingo.de or contact me at
#  welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
#  Lex Lingo rules from here on


require 'sdbm'
require 'digest/sha1'
require 'lib/const'
require 'lib/types'
require 'lib/utilities'
require 'lib/modules'


################################################################################
#
#    ShowPercent ermöglicht die Fortschrittsanzeige beim konvertieren der 
#    Wörterbücher
#
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
#
################################################################################



################################################################################
#
#    Crypter ermöglicht die Ver- und Entschlüsselung von Wörterbüchern
#
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
#
################################################################################


################################################################################
#
#    TxtFile
#
=begin rdoc
== TxtFile
Die Klasse TxtFile stellt eine einheitliche Schnittstelle auf die unterschiedlichen Formate
von Wörterbuch-Quelldateien bereit. Die Identifizierung der Quelldatei erfolgt über die ID
der Datei, so wie sie in der Sprachkonfigurationsdatei <tt>de.lang</tt> unter
<tt>language/dictionary/databases</tt> hinterlegt ist.

Die Verarbeitung der Wörterbücher erfolgt mittels des Iterators <b>each</b>, der für jede 
Zeile der Quelldatei ein Array bereitstellt in der Form <tt>[ key, [val1, val2, ...] ]</tt>.

Nicht korrekt erkannte Zeilen werden abgewiesen und in eine Revoke-Datei gespeichert, die 
an der Dateiendung <tt>.rev</tt> zu erkennen ist.
=end
class TxtFile
  attr_reader :position

  def TxtFile.filename( id )
    #  Konfiguration der Datenbank auslesen
    config = Lingo.config['language/dictionary/databases/' + id]
    raise "Es gibt in 'language/dictionary/databases' keine Datenbank mit der Kurzform '#{id}'" if config.nil? || !config.has_key?( 'name' )
    
    #  Pfade für Quelldatei und für ungültige Zeilen
    config['name']
  end

private

  def initialize( id )
    #  Konfiguration der Datenbank auslesen
    @config = Lingo.config['language/dictionary/databases/' + id]
    
    #  Pfade für Quelldatei und für ungültige Zeilen
    @pn_source = Pathname.new( @config['name'] )
    @pn_reject = Pathname.new( @config['name'].gsub( FILE_EXTENSION_PATTERN, '.rev' ) )

    Lingo.error( "Quelldatei für id '#{id}' unter '" + @config['name'] + "' existiert nicht" ) unless @pn_source.exist?
    
    #  Parameter standardisieren
    @wordclass = @config.fetch( 'def-wc', '?' ).downcase
    @separator = @config['separator']

    #  Objektvariablen initialisieren
    @legal_word = '(?:' + PRINTABLE_CHAR + '|[' + Regexp.escape( '- /&()[].,' ) + '])+'  # TODO: v1.60 - ',' bei TxtFile zulassen; in const.rb einbauen
    @line_pattern = Regexp.new('^'+@legal_word+'$')
    @position = 0
  end


public

  def size
    @pn_source.size
  end
  
  
  def each( &block )
    fail_msg = ''

    begin
      #  Reject-Datei öffnen
      fail_msg = "Fehler beim öffnen der Reject-Datei '#{@pn_reject.to_s}'"
      reject_file = @pn_reject.open( 'w' )

      #  Alle Zeilen der Quelldatei verarbeiten    
      fail_msg = "Fehler beim öffnen der Wörterbuch-Quelldatei '#{@pn_source.to_s}'"

      @pn_source.each_line do |raw_line|
        @position += raw_line.size          #  Position innerhalb der Datei aktualisieren
        line = raw_line.chomp.downcase        #  Zeile normieren

        next if line =~ /^\s*\043/ || line.strip == ''  #  Kommentarzeilen und leere Zeilen überspringen
        
        #  Ungültige Zeilen protokollieren
        unless line.length < 4096 && line =~ @line_pattern
          fail_msg = "Fehler beim schreiben der Reject-Datei '#{@pn_reject.to_s}'"
          reject_file.puts line
          next
        end

        #  Zeile in Werte konvertieren
        yield convert_line( line, $1, $2 )
        
      end  

      fail_msg = "Fehler beim Schließen der Reject-Datei '#{@pn_reject.to_s}'"
      reject_file.close
      @pn_reject.delete if @pn_reject.size == 0
      
    rescue RuntimeError
      Lingo.error( fail_msg )
    end
    
    self
  end

end



=begin rdoc
== TxtFile_Singleword
Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>SingleWord</tt>.
Eine Zeile <tt>"Fachbegriff\n"</tt> wird gewandelt in <tt>[ 'fachbegriff', ['#s'] ]</tt>.
Die Wortklasse kann über den Parameter <tt>def-wc</tt> beeinflusst werden.
=end
class TxtFile_Singleword < TxtFile
private
  def initialize( id )
    super
    @wordclass = @config.fetch( 'def-wc', 's' ).downcase
    @line_pattern = Regexp.new('^(' + @legal_word + ')$')
  end

  def convert_line( line, key, val )
    key = key.strip
    val = ['#' + ((key =~ / /) ? LA_MULTIWORD : @wordclass)]
    [key, val]
  end
end



=begin rdoc
== TxtFile_Keyvalue
Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>KeyValue</tt>.
Eine Zeile <tt>"Fachbegriff*Fachterminus\n"</tt> wird gewandelt in <tt>[ 'fachbegriff', ['fachterminus#s'] ]</tt>.
Die Wortklasse kann über den Parameter <tt>def-wc</tt> beeinflusst werden.
Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.
=end
class TxtFile_Keyvalue < TxtFile
private
  def initialize( id )
    super
    @separator = @config.fetch( 'separator', '*' )
    @line_pattern = Regexp.new('^(' + @legal_word + ')' + Regexp.escape(@separator) + '(' + @legal_word + ')$')
  end

  def convert_line( line, key, val )
    key, val = key.strip, val.strip
    val = '' if key == val
    val = [val + '#' + @wordclass]
    [key, val]
  end        
end



=begin rdoc
== TxtFile_Wordclass
Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>WordClass</tt>.
Eine Zeile <tt>"essen,essen #v essen #o esse #s\n"</tt> wird gewandelt in <tt>[ 'essen', ['esse#s', 'essen#v', 'essen#o'] ]</tt>.
Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.
=end
class TxtFile_Wordclass < TxtFile
private
  def initialize( id )
    super
    @separator = @config.fetch( 'separator', ',' )
    @line_pattern = Regexp.new('^(' + @legal_word + ')' + Regexp.escape(@separator) + '((?:' + @legal_word + '\043\w)+)$')
  end

  def convert_line( line, key, val )
    key, valstr = key.strip, val.strip
    val = valstr.gsub( /\s+\043/, '#' ).scan( /\S.+?\s*\043\w/ )
    val = val.collect do |str| 
      str =~ /^(.+)\043(.)/
      (($1 == key) ? '' : $1) + '#' + $2
    end
    [key, val]
  end        
end



=begin rdoc
== TxtFile_Multivalue
Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>MultiValue</tt>.
Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ nil, ['triumph', 'sieg', 'erfolg'] ]</tt>.
Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.
=end
class TxtFile_Multivalue < TxtFile
private
  def initialize( id )
    super
    @separator = @config.fetch( 'separator', ';' )
    @line_pattern = Regexp.new('^' + @legal_word + '(?:' + Regexp.escape(@separator) + @legal_word + ')*$')
  end

  def convert_line( line, key, val )
    [nil, line.split(@separator).collect { |value| value.strip }]
  end
end



=begin rdoc
== TxtFile_Multikey
Abgeleitet von TxtFile behandelt die Klasse Dateien mit dem Format <tt>MultiKey</tt>.
Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ 'triumph', ['sieg', 'erfolg'] ]</tt>.
Die Sonderbehandlung erfolgt in der Klasse Txt2DbmConverter, wo daraus Schlüssel-Werte-Paare in der Form
<tt>[ 'sieg', ['triumph'] ]</tt> und <tt>[ 'erfolg', ['triumph'] ]</tt> erzeugt werden.
Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.
=end
class TxtFile_Multikey < TxtFile
private
  def initialize( id )
    super
    @separator = @config.fetch( 'separator', ';' )
    @line_pattern = Regexp.new('^' + @legal_word + '(?:' + Regexp.escape(@separator) + @legal_word + ')*$')
  end

  def convert_line( line, key, val )
    values = line.split(@separator).collect { |value| value.strip }
    [values[0], values[1..-1]]
  end
end



=begin rdoc
== DbmFile
Die Klasse DbmFile stellt eine einheitliche Schnittstelle auf Lingo-Datenbanken bereit.
Die Identifizierung der Datenbank erfolgt über die ID der Datenbank, so wie sie in der 
Sprachkonfigurationsdatei <tt>de.lang</tt> unter <tt>language/dictionary/databases</tt>
hinterlegt ist.

Das Lesen und Schreiben der Datenbank erfolgt über die Funktionen []() und []=().
=end
class DbmFile

  include Cachable
  
  INDEX_PATTERN = Regexp.new( '^'+Regexp.escape(IDX_REF)+'\d+$' )

  #  Erzeugt den Dateinamen des DbmFiles anhang der Konfiguration
  def DbmFile.filename( id )
    TxtFile.filename( id ) =~ /^(.+?)([^\/]+?)(?:\.txt){0,1}$/
    $1 + 'store/' + $2
  end


  #  Überprüft die Aktualität des DbmFile
  def DbmFile.uptodate?( id )
    #  Datei ist nicht uptodate
    uptodate = false
    
    #  Dbm-Dateinamen merken
    dbm_name = DbmFile.filename( id )

    #  System-Schlüssel aus Dbm-Datei lesen
    source_key = nil
    begin
      SDBM.open( dbm_name ) do |dbm|
        source_key = dbm[SYS_KEY]
      end
    rescue RuntimeError
    end if FileTest.exist?( dbm_name + '.pag' )

    #  Dbm-Datei existiert und hat Inhalt
    unless source_key.nil?
      #  Mit Werten der Quelldatei vergleichen
      txt_file = Pathname.new( TxtFile.filename( id ) )
      if txt_file.exist?
        txt_stamp = txt_file.size.to_s + FLD_SEP + txt_file.mtime.to_s
        uptodate = ( source_key == txt_stamp )
      else
        uptodate = true
      end
    end

    #  Gib Status zurück
    uptodate
  end

  
private

  def initialize( id, read_mode=true )  
    init_cachable
    
    #  Objektvariablen initialisieren
    @id = id
    @dbm = nil

    #  Aktualität prüfen
    Txt2DbmConverter.new( id ).convert if read_mode && !DbmFile.uptodate?( id )
    
    #  Verschlüsselung vorbereiten
    @crypter = Lingo.config['language/dictionary/databases/' + id].has_key?( 'crypt' ) ? Crypter.new : nil
    
    #  Store-Ordner anlegen
    Pathname.new( DbmFile.filename( id ) ).create_path

    self
  end


public

  def open
    if @dbm.nil?
      @dbm = SDBM.open( DbmFile.filename( @id ) )
    else
      Lingo.error( "DbmFile #{@dbm_name} bereits geöffnet" )
    end
  end

  def to_h
    @dbm.to_hash
  end

  def clear
    pag_file = DbmFile.filename( @id ) + '.pag'
    dir_file = DbmFile.filename( @id ) + '.dir'
    
    unless @dbm.nil?
      close
      File.delete( pag_file )
      File.delete( dir_file )
      open
    else
      File.delete( pag_file ) if File.exist?( pag_file )
      File.delete( dir_file ) if File.exist?( dir_file )
    end
  end

  def close
    unless @dbm.nil?
      @dbm.close
      @dbm = nil
    else
      #Lingo.error( "DbmFile #{@dbm_name} nicht geöffnet" )
    end
  end


  def []( key )
#    return retrieve( key ) if hit?( key )

    val = nil
    unless @dbm.nil? #|| @dbm.closed?
      #  Entschlüsselung behandeln
      if @crypter.nil?
        val = @dbm[key]
      else
        val = @dbm[@crypter.digest( key )]
        val = @crypter.decode( key, val ) unless val.nil?
      end

      #  Äquvalenzklassen behandeln
#      val = @dbm[val] if val =~ INDEX_PATTERN
#      val = val.split( FLD_SEP  ) unless val.nil?
      
      #  Äquvalenzklassen behandeln
      val = val.split( FLD_SEP ).collect do |v|
        (v =~ INDEX_PATTERN) ? @dbm[v] : v
      end.compact.join( FLD_SEP ).split( FLD_SEP ) unless val.nil?
    end

#p val #if val =~ INDEX_PATTERN

    val
  end


  def []=(key, val)
     unless @dbm.nil? #|| @dbm.closed?
      #  Werte im Cache berücksichtigen
      values = hit?( key ) ? val + retrieve( key ) : val
      #  Werte vorsortieren
      values = values.sort.uniq
      #  im Cache merken
      store( key, values )
      #  in String wandeln
      values = values.join( FLD_SEP )
      #  Verschlüsselung behandeln
      if @crypter.nil?
        @dbm[key] = (values.size<950) ? values : values[0...950]
      else
        k, v = @crypter.encode(key, values)
        @dbm[k] = (v.size<950) ? v : v[0...950]
      end
    end
  end


  def set_source_file( filename )
    unless @dbm.nil?
      src = Pathname.new( filename.downcase )
      @dbm[SYS_KEY] = [src.size, src.mtime].join( FLD_SEP )
    end
  end

end




=begin rdoc
== Txt2DbConverter
Die Klasse Txt2DbConverter steuert die Konvertierung von Wörterbuch-Quelldateien in 
Lingo-Datenbanken. Die Identifizierung der Quelldatei erfolgt über die ID
der Datei, so wie sie in der Sprachkonfigurationsdatei <tt>de.lang</tt> unter
<tt>language/dictionary/databases</tt> hinterlegt ist.
=end
class Txt2DbmConverter

private
  def initialize( id, verbose=true )
    #  Konfiguration der Datenbanken auslesen
    @config = Lingo::config['language/dictionary/databases/' + id]
    @index = 0
    
    #  Objekt für Quelldatei erzeugen
    @format = @config.fetch( 'txt-format', 'KeyValue' ).downcase
    case @format
      when 'singleword'  then @source = TxtFile_Singleword.new( id )
      when 'keyvalue'    then @source = TxtFile_Keyvalue.new( id )
      when 'wordclass'  then @source = TxtFile_Wordclass.new( id )
      when 'multivalue'  then @source = TxtFile_Multivalue.new( id )
      when 'multikey'    then @source = TxtFile_Multikey.new( id )
      else
        Lingo.error( "Unbekanntes Textformat '#{config['txt-format'].downcase}' bei '#{'language/dictionary/databases/' + id}'" ) 
    end

    #  Zielobjekt erzeugen
    @destination = DbmFile.new( id, false )

    #    Ausgabesteuerung
    @verbose = verbose
    if @verbose
      @perc = ShowPercent.new( @verbose )
      print @config['name'], ': '
    end

    #  Lexikalisierungen für Mehrwortgruppen vorbereiten
    lex_dic = @config['use-lex']
    lex_mod = @config['lex-mode']

    begin
      @lexicalize = true
      @dictionary = Dictionary.new( {'source'=>lex_dic.split(STRING_SEPERATOR_PATTERN), 'mode'=>lex_mod}, Lingo::config['language/dictionary'] )
      @grammar = Grammar.new( {'source'=>lex_dic.split(STRING_SEPERATOR_PATTERN), 'mode'=>lex_mod}, Lingo::config['language/dictionary'] )
    rescue RuntimeError

      Lingo.error( "Auf das Wörterbuch (#{lex_dic}) für die Lexikalisierung der Mehrwortgruppen in (#{@config['name']}) konnte nicht zugegriffen werden" )
    end unless lex_dic.nil?

    self
  end

public

  def convert
    if @verbose
      print 'convert '
      @perc.start( @source.size )
    end

    @destination.open
    @destination.clear

    @source.each do |key, value|
      @perc.set( @source.position ) if @verbose        #  Status ausgeben

      #  Behandle Mehrwortschlüssel
      if @lexicalize && key =~ / /
        #  Schlüssel in Grundform wandeln
        gkey = key.split( ' ' ).collect do |form|
          
          # => Wortform ohne Satzendepunkt benutzen
          wordform = form.gsub( /\.$/, '' )

          # => Wort suchen
          result = @dictionary.find_word( wordform )

          # => Kompositum suchen, wenn Wort nicht erkannt
          if result.attr == WA_UNKNOWN
            result = @grammar.find_compositum( wordform )
            compo = result.compo_form
          end
          
          compo ? compo.form : result.norm
        end.join( ' ' )
        
        skey = gkey.split
        #  Zusatzschlüssel einfügen, wenn Anzahl Wörter > 3
        @destination[skey[0...3].join( ' ' )] = [KEY_REF + skey.size.to_s] if skey.size > 3
        
        value = value.collect { |v| (v=~/^\043/) ? key+v : v }
        key = gkey    
      end

      #  Format Sonderbehandlungen
      key.gsub!( /\.$/, '' ) unless key.nil?
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
    @destination.set_source_file( @config['name'] )

    @destination.close

    if @verbose
      @perc.stop
      puts 'ok '
    end
    
    self
  end

end


