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
== Noneword_filter
Der Noneword_filter ermöglicht es, alle nicht erkannten Wörter aus dem Datenstrom zu 
selektieren und weiterzuleiten. Im Prinzip werden alle erkannten Wörter gefiltert.
Bei einem Indexierungslauf können so alle nicht durch den Wordsearcher erkannten Wörter, 
also die, die im Wörterbuch nicht enthalten sind, separat ausgegeben werden und als Grundlage für 
die Wörterbuchpflege dienen.
Der Noneword_filter ist in einer frühen Entwicklungsphase entstanden. Die gleiche Funktion 
kann auch mit dem universelleren Objectfilter mit dem Ausdruck 'obj.kind_of?(Word) && obj.attr==WA_UNKNOWN'
durchgeführt werden, mit dem einzigen Unterschied, dass der Noneword_filter nur die Wortform weiterleitet.
Der Noneword_filter verschluckt ebenfalls alle Kommandos, ausser dem Dateianfang (*FILE) und Ende (*EOF),
sowie dem LIR-Format-Spezifikum (*RECORD).

*Hinweis* Dieser Attendee sammelt die auszugebenden Daten so lange, bis ein Dateiwechsel oder Record-Wechsel 
angekündigt wird. Erst dann werden alle Daten auf einmal weitergeleitet.

=== Mögliche Verlinkung
Erwartet:: Daten vom Typ *Word*, z.B. von Abbreviator, Wordsearcher, Decomposer, Synonymer, Multiworder, Sequencer
Erzeugt:: Daten vom Typ *String*, z.B. für Textwriter

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee
<b>out</b>:: siehe allgemeine Beschreibung des Attendee

=== Beispiele
Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader:      { out: lines, files: '$(files)' }
      - tokenizer:       { in: lines, out: token }
      - wordsearcher:    { in: token, out: words, source: 'sys-dic' }
      - noneword_filter: { in: words, out: filtr }
      - debugger:        { in: filtr, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  out> *FILE('test.txt')
  out> "lingo"
  out> *EOF('test.txt')
=end


class Noneword_filter < Attendee

protected

  def init
    @nonewords = []
  end
  
  
  #  Control behandelt die Kommandos zum Öffnen und Schließen einer Datei. 
  #  Für jede Datei wird ein neuer Satz nicht erkannter Wörter registriert.
  def control(cmd, par)
    case cmd
      when STR_CMD_FILE
        @nonewords.clear
      when STR_CMD_EOL
        deleteCmd
      when STR_CMD_RECORD, STR_CMD_EOF
        nones = @nonewords.sort.uniq
        nones.each { |nw| forward(nw) }
        add('Objekte gefiltert', nones.size)
        @nonewords.clear
    end
  end


  def process(obj)
    if obj.is_a?(Word) && obj.attr==WA_UNKNOWN
      inc('Anzahl nicht erkannter Wörter')
      @nonewords << obj.form.downcase
    end
  end
  
end
