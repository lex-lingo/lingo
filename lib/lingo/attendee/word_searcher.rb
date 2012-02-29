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

    # Der WordSearcher ist das Herzstück von Lingo. Er macht die Hauptarbeit und versucht
    # alle Token die nach einem sinnvollen Wort aussehen, in den ihm angegebenen
    # Wörterbüchern zu finden und aufzulösen. Dabei werden die im Wörterbuch gefundenen
    # Grundformen inkl. Wortklassen an das Word-Objekt angehängt.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten vom Typ *Token* (andere werden einfach durchgereicht) z.B. von Tokenizer, Abbreviator
    # Erzeugt:: Daten vom Typ *Word* für erkannte Wörter z.B. für Synonymer, Decomposer, Ocr_variator, Multiworder, Sequencer, Noneword_filter, Vector_filter
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
    #       - debugger:      { in: words, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> <Dies = [(dies/w)]>
    #   out> <ist = [(sein/v)]>
    #   out> <ggf. = [(gegebenenfalls/w)]>
    #   out> <eine = [(einen/v), (ein/w)]>
    #   out> <Abk³rzung = [(abk³rzung/s)]>
    #   out> :./PUNC:
    #   out> *EOL('test.txt')
    #   out> *EOF('test.txt')

    class WordSearcher < self

      def init
        set_dic
      end

      def control(cmd, param)
        report_on(cmd, @dic)
      end

      def process(obj)
        if obj.is_a?(Token) && obj.attr == TA_WORD
          inc('Anzahl gesuchter Wörter')

          obj = @dic.find_word(obj.form)
          inc('Anzahl gefundener Wörter') unless obj.unknown?
        end

        forward(obj)
      end

    end

    # For backwards compatibility.
    Wordsearcher  = WordSearcher
    Word_searcher = WordSearcher

  end

end
