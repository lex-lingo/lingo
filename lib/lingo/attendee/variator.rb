# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2014 John Vorhauer, Jens Wille                           #
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

    #--
    # Der Variator ermöglicht bei nicht erkannten Wörtern den listenbasierten
    # Austausch einzelner Wortteile einchließlich erneuter Wörterbuchsuche zur
    # Verbesserung der Worterkennungsquote.
    #
    # Ursprünglich wurde der Variator entwickelt, um die mangelnde Qualität bei der
    # OCR-Erkennung altdeutscher 's'-Konsonanten zu optimieren. Er kann ebenso bei
    # alternativen Umlautschreibweisen z.B. zur Wandlung von 'Koeln' in 'Köln' dienen.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten vom Typ *Word* (andere werden einfach durchgereicht) z.B. von Wordsearcher
    # Erzeugt:: Daten vom Typ *Word* zur Weiterleitung z.B. an Synonymer, Decomposer, Multiworder, Sequencer, Noneword_filter oder Vector_filter
    #
    # === Parameter
    # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
    # Alle anderen Parameter müssen zwingend angegeben werden.
    # <b>in</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>source</b>:: siehe allgemeine Beschreibung des Dictionary
    # <b><i>mode</i></b>:: (Standard: all) siehe allgemeine Beschreibung des Dictionary
    # <b><i>^check</i></b>:: (Standard: WA_UNKNOWN) Gebrenzt die zu variierenden Worttypen
    # <b><i>marker</i></b>:: (Standard: '*') Kennzeichnung durch Variation erkannter Wörter
    # <b><i>max-var</i></b>:: (Standard: '10000') Begrenzung der maximal zu prüfenden Permutationen bei der vollständigen Kombination aller auf ein Wort anzuwendenen aufgelisteten Wortteile.
    #
    # === Beispiele
    # Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader:   { out: lines, files: '$(files)' }
    #       - tokenizer:     { in: lines, out: token }
    #       - word_searcher: { in: abbrev, out: words, source: 'sys-dic' }
    #       - variator:      { in: words, out: varios, source: 'sys-dic' }
    #       - debugger:      { in: varios, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> <*Dies = [(dies/w)]>
    #   out> <*ist = [(ist/t)]>
    #   out> <ein = [(ein/t)]>
    #   out> <*Tisch = [(tisch/s)]>
    #   out> :./PUNC:
    #   out> *EOL('test.txt')
    #   out> *EOF('test.txt')
    #++

    class Variator < self

      protected

      def init
        @marker = get_key('marker', '*')
        @max    = get_key('max-var', max = 10000).to_i
        @max    = max unless @max > 0
        @var    = get_key('variations')

        raise MissingConfigError.new(:variations) if @var.empty?

        @check = Hash.new(false)
        get_array('check', WA_UNKNOWN).each { |s| @check[s.upcase] = true }

        set_dic
        set_gra
      end

      def control(*)
        # can control
      end

      def process(obj)
        if obj.is_a?(Word) && @check[obj.attr]
          vars, max = [obj.form], @max

          @var.each { |args|
            variate(vars, *args)
            break unless vars.length < max
          }

          vars.each { |var|
            next if (word = find_word(var)).unknown? || (
              word.attr == WA_COMPOUND && word.lexicals.any? { |lex|
                lex.attr.start_with?(LA_TAKEITASIS)
              }
            )

            return forward(word.tap { word.form = @marker + var })
          }
        end

        forward(obj)
      end

      private

      def variate(variations, from, to)
        add, change, re = [], [from, to], Regexp.new(from)

        variations.each { |form|
          parts = " #{form} ".split(re)

          1.upto(2 ** (n = parts.size - 1) - 1) { |i|
            var = parts.first
            1.upto(n) { |j| var += change[i[j - 1]] + parts[j] }
            add << var.strip
          }
        }

        variations.concat(add)
      end

    end

  end

end
