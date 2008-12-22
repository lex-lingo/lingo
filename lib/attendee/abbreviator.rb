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
== Abbreviator
Die Erkennung von Abkürzungen kann auf vielfältige Weise erfolgen. In jedem Fall 
sollte eine sichere Unterscheidung von einem Satzende-Punkt möglich sein.
Der in Lingo gewählte Ansatz befreit den Tokenizer von dieser Arbeit und konzentriert
die Erkennung in diesem Attendee.
Sobald der Abbreviator im Datenstrom auf ein Punkt trifft (Token = <tt>:./PUNC:</tt>), 
prüft er das vorhergehende Token auf eine gültige Abkürzung im Abkürzungs-Wörterbuch.
Wird es als Abkürzung erkannt, dann wird das Token in ein Word gewandelt und das 
Punkt-Token aus dem Zeichenstrom entfernt.

=== Mögliche Verlinkung
Erwartet:: Daten des Typs *Token* z.B. von Tokenizer
Erzeugt:: Leitet Token weiter und wandelt erkannte Abkürzungen in den Typ *Word* z.B. für Wordsearcher

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee
<b>out</b>:: siehe allgemeine Beschreibung des Attendee
<b>source</b>:: siehe allgemeine Beschreibung des Dictionary
<b><i>mode</i></b>:: (Standard: all) siehe allgemeine Beschreibung des Dictionary

=== Beispiele
Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader:  { out: lines, files: '$(files)' }
      - tokenizer:   { in: lines, out: token }
      - abbreviator: { in: token, out: abbrev, source: 'sys-abk' }
      - debugger:    { in: abbrev, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  out> *FILE('test.txt')
  out> :Dies/WORD:
  out> :ist/WORD:
  out> <ggf. = [(gegebenenfalls/w)]>
  out> :eine/WORD:
  out> :Abk³rzung/WORD:
  out> :./PUNC:
  out> *EOL('test.txt')
  out> *EOF('test.txt')  
=end


class Attendee::Abbreviator < BufferedAttendee

protected

  def init
    #  Wörterbuch bereitstellen
    src = get_array('source')
    mod = get_key('mode', 'all')
    @dic = Dictionary.new({'source'=>src, 'mode'=>mod}, @@library_config)
  end


  def control(cmd, par)
    @dic.report.each_pair { |key, value| set(key, value) } if cmd == STR_CMD_STATUS

    #  Jedes Control-Object ist auch Auslöser der Verarbeitung
    process_buffer
  end


private

  def process_buffer?
    @buffer[-1].kind_of?(Token) && @buffer[-1].form == CHAR_PUNCT
  end


  def process_buffer
    if @buffer.size < 2
      forward_buffer
      return
    end

    #  Wort vor dem Punkt im Abkürzungswörterbuch suchen
    if @buffer[-2].kind_of?(Token)
      inc('Anzahl gesuchter Abkürzungen')
      abbr = @dic.find_word(@buffer[-2].form)
      if abbr.attr == WA_IDENTIFIED
        inc('Anzahl gefundener Abkürzungen')
        abbr.form += CHAR_PUNCT
        @buffer[-2] = abbr
        @buffer.delete_at(-1)
      end
    end
    
    forward_buffer
  end
  
end
