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

    # Der Synonymer untersucht die von anderen Attendees ermittelten Grundformen eines Wortes
    # und sucht in den angegebenen Wörterbüchern nach Relationen zu anderen Grundformen.
    # Gefundene Relationen erweitern die Liste des Word-Objektes und werden zur späteren
    # Identifizierung mit der Wortklasse 'y' gekennzeichnet.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten vom Typ *Word* z.B. von Wordsearcher, Decomposer, Ocr_variator, Multiworder
    # Erzeugt:: Daten vom Typ *Word* (ggf. um Relationen ergänzt) z.B. für Decomposer, Ocr_variator, Multiworder, Sequencer, Noneword_filter, Vector_filter
    #
    # === Parameter
    # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
    # Alle anderen Parameter müssen zwingend angegeben werden.
    # <b>in</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>source</b>:: siehe allgemeine Beschreibung des Dictionary
    # <b><i>mode</i></b>:: (Standard: all) siehe allgemeine Beschreibung des Dictionary
    # <b><i>skip</i></b>:: (Standard: WA_UNKNOWN [siehe strings.rb]) Veranlasst den Synonymer
    #                      Wörter mit diesem Attribut zu überspringen.
    #
    # === Beispiele
    # Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader:   { out: lines, files: '$(files)' }
    #       - tokenizer:     { in: lines, out: token }
    #       - abbreviator:   { in: token, out: abbrev, source: 'sys-abk' }
    #       - word_searcher: { in: abbrev, out: words, source: 'sys-dic' }
    #       - synonymer:     { in: words, out: synos, source: 'sys-syn' }
    #       - debugger:      { in: words, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> <Dies = [(dies/w), (das/y), (dies/y)]>
    #   out> <ist = [(sein/v), ((sich) befinden/y), (dasein/y), (existenz/y), (sein/y), (vorhandensein/y)]>
    #   out> <ggf. = [(gegebenenfalls/w), (bei bedarf/y), (gegebenenfalls/y), (ggf./y), (notfalls/y)]>
    #   out> <eine = [(einen/v), (ein/w)]>
    #   out> <Abk³rzung = [(abk³rzung/s), (abbreviation/y), (abbreviatur/y), (abk³rzung/y), (akronym/y), (kurzbezeichnung/y)]>
    #   out> :./PUNC:
    #   out> *EOL('test.txt')
    #   out> *EOF('test.txt')

    class Synonymer < self

      protected

      def init
        set_dic
        @skip = get_array('skip', WA_UNKNOWN, :upcase)
      end

      def control(cmd, param)
      end

      def process(obj)
        if obj.is_a?(Word) && !@skip.include?(obj.attr)
          obj.add_lexicals(@dic.find_synonyms(obj))
        end

        forward(obj)
      end

    end

  end

end
