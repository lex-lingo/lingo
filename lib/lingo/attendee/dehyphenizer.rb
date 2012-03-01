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

    # Der Dehyphenizer ... muss noch dokumentiert werden
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten vom Typ *Word* z.B. von Wordsearcher, Decomposer, Ocr_variator, Multiworder
    # Erzeugt:: Daten vom Typ *Word* (mit Attribut WA_MULTIWORD). Je erkannter Mehrwortgruppe wird ein zusätzliches Word-Objekt in den Datenstrom eingefügt. Z.B. für Ocr_variator, Sequencer, Noneword_filter, Vector_filter
    #
    # === Parameter
    # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
    # Alle anderen Parameter müssen zwingend angegeben werden.
    # <b>in</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>source</b>:: siehe allgemeine Beschreibung des Dictionary
    # <b><i>mode</i></b>:: (Standard: all) siehe allgemeine Beschreibung des Dictionary
    # <b><i>stopper</i></b>:: (Standard: TA_PUNCTUATION, TA_OTHER) Gibt die Begrenzungen an, zwischen
    #                         denen der Multiworder suchen soll, i.d.R. Satzzeichen und Sonderzeichen,
    #                         weil sie kaum in einer Mehrwortgruppen vorkommen.
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
    #       - multi_worder:  { in: comps, out: multi, source: 'sys-mul' }
    #       - debugger:      { in: multi, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> <Sein = [(sein/s), (sein/v)]>
    #   out> <Name = [(name/s)]>
    #   out> <ist = [(sein/v)]>
    #   out> <johann van siegen|MUL = [(johann van siegen/m)]>
    #   out> <Johann = [(johann/e)]>
    #   out> <van = [(van/w)]>
    #   out> <Siegen = [(sieg/s), (siegen/v), (siegen/e)]>
    #   out> :./PUNC:
    #   out> *EOL('test.txt')
    #   out> *EOF('test.txt')

    class Dehyphenizer < BufferedAttendee

      protected

      def init
        set_dic
        set_gra

        @skip = get_array('skip', '', :downcase)

        @expected_tokens_in_buffer, @eof_handling = 2, false
      end

      def control(cmd, param)
        control_multi(cmd)
      end

      def process_buffer
        if @buffer[0].is_a?(Word) &&
          @buffer[0].form[-1..-1] == '-' &&
          @buffer[1].is_a?(Word) &&
          !(!( ttt = @buffer[1].get_class(/./) ).nil? &&
          !@skip.index( ttt[0].attr ).nil?)

          # Einfache Zusammensetzung versuchen
          form = @buffer[0].form[0...-1] + @buffer[1].form
          word = @dic.find_word(form)
          word = @gra.find_compound(form) unless word.identified?

          unless word.identified? || (word.attr == WA_COMPOUND && word.get_class('x+').empty?)
            # Zusammensetzung mit Bindestrich versuchen
            form = @buffer[0].form + @buffer[1].form
            word = @dic.find_word(form)
             word = @gra.find_compound(form) unless word.identified?
          end

          unless word.identified? || (word.attr == WA_COMPOUND && word.get_class('x+').empty?)
            # Zusammensetzung mit Bindestrich versuchen
            form = @buffer[0].form + @buffer[1].form
            word = @dic.find_word(form)
            word = @gra.find_compound(form) unless word.identified?
          end

          if word.identified? || (word.attr == WA_COMPOUND && word.get_class('x+').empty?)
            @buffer[0] = word
            @buffer.delete_at( 1 )
          end
        end

        # Buffer weiterschaufeln
        forward_number_of_token( 1, false )
      end

    end

  end

end
