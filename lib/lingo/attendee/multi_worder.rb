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
    #                         denen der MultiWorder suchen soll, i.d.R. Satzzeichen und Sonderzeichen,
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

    class MultiWorder < BufferedAttendee

      protected

      def init
        @stopper = get_array('stopper', DEFAULT_SKIP).map(&:upcase)
        @mul_dic = dictionary(mul_src = get_array('source'), get_key('mode', 'all'))

        # combine lexical variants?
        #
        # false = old behaviour
        # true  = first match
        # 'all' = all matches
        @combine  = get_key('combine', false)
        @all_keys = @combine.is_a?(String) && @combine.downcase == 'all'

        lex_src, lex_mod, databases = nil, nil, @lingo.dictionary_config['databases']

        mul_src.each { |src|
          this_src, this_mod = databases[src].values_at('use-lex', 'lex-mode')
          if lex_src.nil? || lex_src == this_src
            lex_src, lex_mod = this_src, this_mod
          else
            @lingo.warn "#{self.class}: Dictionaries don't match: #{mul_src.join(',')}"
          end
        }

        lex_src = lex_src.split(STRING_SEPARATOR_RE)
        lex_mod = get_key('lex-mode', lex_mod || 'first')

        @lex_dic = dictionary(lex_src, lex_mod)
        @lex_gra = grammar(lex_src, lex_mod)

        if @combine && has_key?('use-syn')
          @syn_dic = dictionary(get_array('use-syn'), get_key('syn-mode', 'all'))
        end

        @expected_tokens_in_buffer = 3
        @eof_handling = false
      end

      def control(cmd, param)
        control_multi(cmd, @mul_dic)
      end

      def process_buffer
        unless @buffer[0].form == CHAR_PUNCT
          # Prüfe 3er Schlüssel
          result = check_multiword_key( 3 )
          unless result.empty?
            # 3er Schlüssel gefunden
            lengths = sort_result_len( result )
            unless lengths[0] > 3
              # Längster erkannter Schlüssel = 3
              create_and_forward_multiword( 3, result )
              forward_number_of_token( 3 )
              return
            else
              # Längster erkannter Schlüssel > 3, Buffer voll genug?
              unless @buffer.size >= lengths[0] || @eof_handling
                @expected_tokens_in_buffer = lengths[0]
                return
              else
                # Buffer voll genug, Verarbeitung kann beginnen
                catch( :forward_one ) do
                  lengths.each do |len|
                    result = check_multiword_key( len )
                    unless result.empty?
                      create_and_forward_multiword( len, result )
                      forward_number_of_token( len )
                      throw :forward_one
                    end
                  end

                  # Keinen Match gefunden
                  forward_number_of_token( 1 )
                end

                @expected_tokens_in_buffer = 3
                process_buffer if process_buffer?
                return
              end
            end
          end

          # Prüfe 2er Schlüssel
          result = check_multiword_key( 2 )
          unless result.empty?
            create_and_forward_multiword( 2, result )
            forward_number_of_token( 1 )
          end
        end

        # Buffer weiterschaufeln
        forward_number_of_token( 1, false )
        @expected_tokens_in_buffer = 3
      end

      private

      def create_and_forward_multiword( len, lexicals )
        # Form aus Buffer auslesen und Teile markieren
        pos = 0
        form_parts = []
        begin
          if @buffer[pos].form == CHAR_PUNCT
            @buffer.delete_at( pos )
            form_parts[-1] += CHAR_PUNCT
          else
            @buffer[pos].attr = WA_UNKMULPART if @buffer[pos].unknown?
            form_parts << @buffer[pos].form
            pos += 1
          end
        end while pos < len

        form = form_parts.join( ' ' )

        # Multiword erstellen
        word = Word.new( form, WA_MULTIWORD )
        word << lexicals.collect { |lex| (lex.is_a?(Lexical)) ? lex : nil }.compact  # FIXME 1.60 - Ausstieg bei "*5" im Synonymer

        # Forword Multiword
        forward( word )
      end

      # Ermittelt die maximale Ergebnislänge
      def sort_result_len( result )
        result.collect do |res|
          if res.is_a?( Lexical )
            res.form.split( ' ' ).size
          else
            res =~ /^\*(\d+)/
            $1.to_i
          end
        end.sort.reverse
      end

      # Prüft einen definiert langen Schlüssel ab Position 0 im Buffer
      def check_multiword_key( len )
        return [] if valid_tokens_in_buffer < len

        # Wortformen aus der Wortliste auslesen
        sequence = @buffer.map { |obj|
          next [obj] unless obj.is_a?(WordForm)

          form = obj.form
          next if form == CHAR_PUNCT

          word = @lex_dic.find_word(form)
          word = @lex_gra.find_compound(form) if word.unknown?

          lexicals = word.attr == WA_KOMPOSITUM ?
            [word.lexicals.first] : word.lexicals.dup

          lexicals << word if lexicals.empty?
          lexicals += @syn_dic.find_synonyms(word) if @syn_dic

          lexicals.map { |lex| lex.form }.uniq
        }.compact[0, len]

        if @combine
          keys, muls = [], []

          sequence.each { |forms|
            keys = forms.map { |form|
              keys.empty? ? form : keys.map { |key| "#{key} #{form}" }
            }.flatten(1)
          }

          keys.each { |key|
            mul = @mul_dic.select(key.downcase)

            unless mul.empty?
              muls.concat(mul)
              break unless @all_keys
            end
          }

          muls.uniq
        else
          key = sequence.map { |forms| forms.first }.join(' ')
          @mul_dic.select(key.downcase)
        end
      end

    end

    # For backwards compatibility.
    Multiworder  = MultiWorder
    Multi_worder = MultiWorder

  end

end
