# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2015 John Vorhauer, Jens Wille                           #
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
    # Mit der bisher beschriebenen Vorgehensweise werden die durch den Tokenizer erkannten
    # Token aufgelöst und in Words verwandelt und über den Abbreviator und Decomposer auch
    # Spezialfälle behandelt, die einzelne Wörter betreffen.
    # Um jedoch auch Namen wie z.B. John F. Kennedy als Sinneinheit erkennen zu können, muss
    # eine Analyse über mehrere Objekte erfolgen. Dies ist die Hauptaufgabe des MultiWorders.
    # Der MultiWorder analysiert die Teile des Datenstroms, die z.B. durch Satzzeichen oder
    # weiteren Einzelzeichen (z.B. '(') begrenzt sind. Erkannte Mehrwortgruppen werden als
    # zusätzliches Objekt in den Datenstrom mit eingefügt.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten vom Typ *Word* z.B. von Wordsearcher, Decomposer, Ocr_variator, MultiWorder
    # Erzeugt:: Daten vom Typ *Word* (mit Attribut WA_MULTIWORD). Je erkannter Mehrwortgruppe wird
    # ein zusätzliches Word-Objekt in den Datenstrom eingefügt. Z.B. für Ocr_variator, Sequencer,
    # Noneword_filter, Vector_filter
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
    #++

    class MultiWorder < BufferedAttendee

      def init
        # combine lexical variants?
        #
        # false = old behaviour
        # true  = first match
        # 'all' = all matches
        @combine = get_key('combine', false)
        @all     = @combine.is_a?(String) && @combine.downcase == 'all'

        lex_src, lex_mod, d = nil, nil, lingo.dictionary_config['databases']

        (mul_src = get_array('source')).each { |src|
          s, m = d[src].values_at('use-lex', 'lex-mode')

          if lex_src.nil? || lex_src == s
            lex_src, lex_mod = s, m
          else
            warn "#{self.class}: Dictionaries don't match: #{mul_src.join(',')}"
          end
        }

        lex_src = lex_src.split(SEP_RE)
        lex_mod = get_key('lex-mode', lex_mod || 'first')

        @mul_dic = dictionary(mul_src, get_key('mode', 'all'))
        @lex_dic = dictionary(lex_src, lex_mod)
        @lex_gra = grammar(lex_src, lex_mod)

        @syn_dic = if @combine && has_key?('use-syn')
          dictionary(get_array('use-syn'), get_key('syn-mode', 'all'))
        end

        @expected_tokens_in_buffer, @eof_handling = 3, false
      end

      def control(cmd, *)
        if [:RECORD, :EOF].include?(cmd)
          @eof_handling = true

          while valid_tokens_in_buffer > 1
            process_buffer
          end

          forward_number_of_token

          @eof_handling = false
        end
      end

      private

      def form_at(index)
        obj = @buffer[index]
        obj.form if obj.is_a?(WordForm)
      end

      def forward_number_of_token(len = default = @buffer.size, punct = !default)
        begin
          unless @buffer.empty?
            forward(item = @buffer.delete_at(0))
            len -= 1 unless punct && item.form == CHAR_PUNCT
          end
        end while len > 0
      end

      def valid_tokens_in_buffer
        @buffer.count { |item| item.form != CHAR_PUNCT }
      end

      def process_buffer?
        valid_tokens_in_buffer >= @expected_tokens_in_buffer
      end

      def process_buffer
        unless form_at(0) == CHAR_PUNCT
          unless (res = check_multiword_key(3)).empty?
            len = res.map { |r| r.is_a?(Lexical) ? r.form.count(' ') + 1 : r }
            len.sort!.reverse!

            unless (max = len.first) > 3
              create_and_forward_multiword(3, res)
              forward_number_of_token(3)
            else
              unless @eof_handling || @buffer.size >= max
                @expected_tokens_in_buffer = max
              else
                forward_number_of_token(len.find { |l|
                  r = check_multiword_key(l)
                  create_and_forward_multiword(l, r) unless r.empty?
                } || 1)

                @expected_tokens_in_buffer = 3
                process_buffer if process_buffer?
              end
            end

            return
          end

          unless (res = check_multiword_key(2)).empty?
            create_and_forward_multiword(2, res)
            forward_number_of_token(1)
          end
        end

        forward_number_of_token(1, false)
        @expected_tokens_in_buffer = 3
      end

      def create_and_forward_multiword(len, lex)
        pos, parts = 0, []

        begin
          if (form = form_at(pos)) == CHAR_PUNCT
            @buffer.delete_at(pos)
            parts[-1] += CHAR_PUNCT
          else
            @buffer[pos].attr = WA_UNKMULPART if @buffer[pos].unknown?
            parts << form
            pos += 1
          end
        end while pos < len

        forward(Word.new_lexicals(parts.join(' '),
          WA_MULTIWORD, lex.select { |l| l.is_a?(Lexical) }))
      end

      def check_multiword_key(len)
        return [] if valid_tokens_in_buffer < len

        seq = []

        @buffer.each { |obj|
          next seq << [obj] unless obj.is_a?(WordForm)
          next if (form = obj.form) == CHAR_PUNCT

          w = find_word(form, @lex_dic, @lex_gra)
          l = w.lexicals

          i = w.attr == WA_COMPOUND ? [l.first] : l.empty? ? [w] : l.dup

          @syn_dic.find_synonyms(w, i) if @syn_dic
          i.map! { |j| Unicode.downcase(j.form) }.uniq!

          seq << i

          break unless seq.length < len
        }

        if @combine
          mul = []

          seq.shift.product(*seq) { |key|
            @mul_dic.select(key.join(' '), mul)
            break unless @all || mul.empty?
          } && mul.uniq!

          mul
        else
          @mul_dic.select(seq.map! { |i,| i }.join(' '))
        end
      end

    end

    # For backwards compatibility.
    Multiworder  = MultiWorder
    Multi_worder = MultiWorder

  end

end
