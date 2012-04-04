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

class Lingo

  class Attendee

    # Komposita, also zusammengesetzte Wörter, sind eine Spezialität der deutschen Sprache
    # (z.B. Indexierungssystem oder Kompositumerkennung).
    # Könnte man alle Kombinationen in den Wörterbüchern hinterlegen, dann würde der
    # Wordsearcher die Erkennung bereits erledigt haben. Die hohe Anzahl der möglichen
    # Kombinationen verbietet jedoch einen solchen Ansatz aufgrund des immensen Pflegeaufwands,
    # eine algorithmische Lösung erscheint sinnvoller.
    # Der Decomposer wertet alle vom Wordsearcher nicht erkannten Wörter aus und prüft sie
    # auf Kompositum.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten vom Typ *Word* (andere werden einfach durchgereicht) z.B. von Wordsearcher
    # Erzeugt:: Daten vom Typ *Word* (erkannte Komposita werden entsprechend erweitert) z.B. für Synonymer, Ocr_variator, Multiworder, Sequencer, Noneword_filter, Vector_filter
    #
    # === Parameter
    # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
    # Alle anderen Parameter müssen zwingend angegeben werden.
    # <b>in</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>source</b>:: siehe allgemeine Beschreibung des Dictionary
    # <b><i>mode</i></b>:: (Standard: all) siehe allgemeine Beschreibung des Dictionary
    #
    # === Beispiele
    # Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader:   { out: lines, files: '$(files)' }
    #       - tokenizer:     { in: lines, out: token }
    #       - abbreviator:   { in: token, out: abbrev, source: 'sys-abk' }
    #       - word_searcher: { in: abbrev, out: words, source: 'sys-dic' }
    #       - decomposer:    { in: words, out: comps, source: 'sys-dic' }
    #       - debugger:      { in: comps, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> <Lingo|?>
    #   out> :,/PUNC:
    #   out> <ein = [(ein/w)]>
    #   out> <Indexierungssystem|KOM = [(indexierungssystem/k), (indexierung/s), (system/s)]>
    #   out> <mit = [(mit/w)]>
    #   out> <Kompositumerkennung|KOM = [(kompositumerkennung/k), (erkennung/s), (kompositum/s)]>
    #   out> :./PUNC:
    #   out> *EOL('test.txt')
    #   out> *EOF('test.txt')

    class Decomposer < self

      protected

      def init
        set_gra
      end

      def control(cmd, param)
        report_on(cmd, @gra)
      end

      def process(obj)
        if obj.is_a?(Word) && obj.unknown?
          com = @gra.find_compound(obj.form)
          obj = com unless com.unknown?
        end

        forward(obj)
      end

    end

  end

end
