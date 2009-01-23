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


=begin rdoc
== Decomposer
Komposita, also zusammengesetzte Wörter, sind eine Spezialität der deutschen Sprache 
(z.B. Indexierungssystem oder Kompositumerkennung).
Könnte man alle Kombinationen in den Wörterbüchern hinterlegen, dann würde der 
Wordsearcher die Erkennung bereits erledigt haben. Die hohe Anzahl der möglichen 
Kombinationen verbietet jedoch einen solchen Ansatz aufgrund des immensen Pflegeaufwands,
eine algorithmische Lösung erscheint sinnvoller.
Der Decomposer wertet alle vom Wordsearcher nicht erkannten Wörter aus und prüft sie
auf Kompositum.

=== Mögliche Verlinkung
Erwartet:: Daten vom Typ *Word* (andere werden einfach durchgereicht) z.B. von Wordsearcher
Erzeugt:: Daten vom Typ *Word* (erkannte Komposita werden entsprechend erweitert) z.B. für Synonymer, Ocr_variator, Multiworder, Sequencer, Noneword_filter, Vector_filter

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
      - textreader:   { out: lines, files: '$(files)' }
      - tokenizer:    { in: lines, out: token }
      - abbreviator:  { in: token, out: abbrev, source: 'sys-abk' }
      - wordsearcher: { in: abbrev, out: words, source: 'sys-dic' }
      - decomposer:   { in: words, out: comps, source: 'sys-dic' }
      - debugger:     { in: comps, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  out> *FILE('test.txt')
  out> <Lingo|?>
  out> :,/PUNC:
  out> <ein = [(ein/w)]>
  out> <Indexierungssystem|KOM = [(indexierungssystem/k), (indexierung/s), (system/s)]>
  out> <mit = [(mit/w)]>
  out> <Kompositumerkennung|KOM = [(kompositumerkennung/k), (erkennung/s), (kompositum/s)]>
  out> :./PUNC:
  out> *EOL('test.txt')
  out> *EOF('test.txt')
=end


class Attendee::Decomposer < Attendee

protected

  def init
    #  Wörterbuch bereitstellen
    src = get_array('source')
    mod = get_key('mode', 'all')
    @grammar = Grammar.new({'source'=>src, 'mode'=>mod}, @@library_config)
  end


  def control(cmd, par)
    @grammar.report.each_pair { |key, value|
      set(key, value) 
    } if cmd == STR_CMD_STATUS
  end


  def process(obj)
    if obj.is_a?(Word) && obj.attr == WA_UNKNOWN
      obj = @grammar.find_compositum(obj.form)
    end
    forward(obj)
  end

end
