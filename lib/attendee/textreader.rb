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


=begin rdoc
== Textreader
Der Textreader ist eine klassische Datenquelle. Er liest eine oder mehrere Dateien  
und gibt sie Zeilenweise in den Ausgabekanal. Der Start bzw. Wechsel einer Datei 
wird dabei über den Kommandokanal angekündigt, ebenso wie das Ende.

Der Textreader kann ebenfalls ein spezielles Dateiformat verarbeiten, welches zum 
Austausch mit dem LIR-System dient. Dabei enthält die Datei Record-basierte Informationen,
die wie mehrere Dateien verarbeitet werden.

=== Mögliche Verlinkung
Erzeugt:: Daten des Typs *String* (Textzeile) z.B. für Tokenizer, Textwriter

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>out</b>:: siehe allgemeine Beschreibung des Attendee
<b>files</b>:: Es können eine oder mehrere Dateien angegeben werden, die nacheinander 
               eingelesen und zeilenweise weitergeleitet werden. Die Dateien werden mit 
               Komma voneinander getrennt, z.B.
                 files: 'readme.txt'
                 files: 'readme.txt,lingo.cfg'
<b><i>lir-record-pattern</i></b>:: Mit diesem Parameter wird angegeben, woran der Anfang 
                                   eines neuen Records erkannt werden kann und wie die 
                                   Record-Nummer identifiziert wird. Das Format einer 
                                   LIR-Datei ist z.B.
                                     [00001.]
                                     020: ¬Die Aufgabenteilung zwischen Wortschatz und Grammatik.

                                     [00002.]
                                     020: Nicht-konventionelle Thesaurusrelationen als Orientierungshilfen.
                                   Mit der Angabe von
                                     lir-record-pattern: "^\[(\d+)\.\]"
                                   werden die Record-Zeilen erkannt und jeweils die Record-Nummer +00001+,
                                   bzw. +00002+ erkannt. 

=== Generierte Kommandos
Damit der nachfolgende Datenstrom einwandfrei verarbeitet werden kann, generiert der Textreader
Kommandos, die mit in den Datenstrom eingefügt werden. 
<b>*FILE(<dateiname>)</b>:: Kennzeichnet den Beginn der Datei <dateiname>
<b>*EOF(<dateiname>)</b>:: Kennzeichnet das Ende der Datei <dateiname>
<b>*LIR_FORMAT('')</b>:: Kennzeichnet die Verarbeitung einer Datei im LIR-Format (nur bei LIR-Format).
<b>*RECORD(<nummer>)</b>:: Kennzeichnet den Beginn eines neuen Records (nur bei LIR-Format).
=== Beispiele
Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader: { out: lines, files: '$(files)' }
      - debugger:   { in: lines, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  out> *FILE('test.txt')
  out> "Dies ist eine Zeile."
  out> "Dies ist noch eine."
  out> *EOF('test.txt')
Bei der Verarbeitung einer LIR-Datei mit der Ablaufkonfiguration <tt>t2.cfg</tt>
  meeting:
    attendees:
      - textreader: { out: lines,  files: '$(files)', lir-record-pattern: "^\[(\d+)\.\]" }
      - debugger:   { in: lines, prompt: 'out>'}
ergibt die Ausgabe mit <tt>lingo -c t2 lir.txt</tt>
  out> *LIR-FORMAT('')
  out> *FILE('lir.txt')
  out> *RECORD('00001')
  out> "020: \254Die Aufgabenteilung zwischen Wortschatz und Grammatik."
  out> *RECORD('00002')
  out> "020: Nicht-konventionelle Thesaurusrelationen als Orientierungshilfen."
  out> *EOF('lir.txt')
=end


class Attendee::Textreader < Attendee

protected

  #   TODO: FILE und LIR-FILE
  #  TODO: lir-record-pattern abkürzen
  #  Interpretation der Parameter
  def init
    @files = get_array('files')
    @rec_pat = Regexp.new(get_key('lir-record-pattern', ''))
    @is_LIR_file = has_key?('lir-record-pattern')
  end


  def control(cmd, param)
    if cmd==STR_CMD_TALK
      forward(STR_CMD_LIR, '') if @is_LIR_file
      @files.each { |filename| spool(filename) }
    end
  end


private

  #  Gibt eine Datei zeilenweise in den Ausgabekanal
  def spool(filename)
    unless stdin?(filename)
      FileTest.exist?(filename) || forward(STR_CMD_ERR, "Datei #{filename} nicht gefunden")

      inc('Anzahl Dateien')
      add('Anzahl Bytes', File.stat(filename).size)
    end

    forward(STR_CMD_FILE, filename)

    (stdin?(filename) ? $stdin : File.open(filename)).each_line { |line|
      inc('Anzahl Zeilen')
      line.chomp!
      line.gsub!(/\303\237/, "ß")
### HACK
      if @is_LIR_file && line =~ @rec_pat
        forward(STR_CMD_RECORD, $1)
      else
        forward(line) if line.size>0
      end
    }

    forward(STR_CMD_EOF, filename)
  end

  def stdin?(filename)
    %w[STDIN -].include?(filename)
  end

end
