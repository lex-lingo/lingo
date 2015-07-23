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
    # Der Sequencer ist von seiner Funktion her ähnlich dem Multiworder. Der Multiworder
    # nutzt zur Erkennung von Mehrwortgruppen spezielle Wörterbücher, der Sequencer hingegen
    # definierte Folgen von Wortklassen. Mit dem Sequencer können Indexterme generiert werden,
    # die sich über mehrere Wörter erstrecken.
    # Die Textfolge "automatische Indexierung und geniale Indexierung"
    # wird bisher in die Indexterme "automatisch", "Indexierung" und "genial" zerlegt.
    # Über die Konfiguration kann der Sequencer Mehrwortgruppen identifizieren, die
    # z.B. aus einem Adjektiv und einem Substantiv bestehen. Mit der o.g. Textfolge würde
    # dann auch "Indexierung, automatisch" und "Indexierung, genial" als Indexterm erzeugt
    # werden. Welche Wortklassenfolgen erkannt werden sollen und wie die Ausgabe aussehen
    # soll, wird dem Sequencer über seine Konfiguration mitgeteilt.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten vom Typ *Word* z.B. von Wordsearcher, Decomposer, Ocr_variator, Multiworder
    # Erzeugt:: Daten vom Typ *Word* (mit Attribut WA_SEQUENCE). Je erkannter Mehrwortgruppe wird
    # ein zusätzliches Word-Objekt in den Datenstrom eingefügt. Z.B. für Ocr_variator, Sequencer,
    # Vector_filter
    #
    # === Parameter
    # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
    # Alle anderen Parameter müssen zwingend angegeben werden.
    # <b>in</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
    # <b><i>stopper</i></b>:: (Standard: TA_PUNCTUATION, TA_OTHER) Gibt die Begrenzungen an, zwischen
    #                         denen der Sequencer suchen soll, i.d.R. Satzzeichen und Sonderzeichen,
    #                         weil sie kaum in einer Mehrwortgruppen vorkommen.
    #
    # === Konfiguration
    # Der Sequencer benötigt zur Identifikation von Mehrwortgruppen Regeln, nach denen er
    # arbeiten soll. Die benötigten Regeln werden nicht als Parameter, sondern in der
    # Sprachkonfiguration hinterlegt, die sich standardmäßig in der Datei
    # <tt>de.lang</tt> befindet (YAML-Format).
    #   language:
    #     attendees:
    #       sequencer:
    #         sequences: [ [AS, "2, 1"], [AK, "2, 1"] ]
    # Hiermit werden dem Sequencer zwei Regeln mitgeteilt: Er soll Adjektiv-Substantiv- (AS) und
    # Adjektiv-Kompositum-Folgen (AK) erkennen. Zusätzlich ist angegeben, in welchem Format die
    # dadurch ermittelte Wortfolge ausgegeben werden soll. In diesem Beispiel also zuerst das
    # Substantiv und durch Komma getrennt das Adjektiv.
    #
    # === Beispiele
    # Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader:   { out: lines, files: '$(files)' }
    #       - tokenizer:     { in: lines, out: token }
    #       - word_searcher: { in: token, out: words, source: 'sys-dic' }
    #       - sequencer:     { in: words, out: seque }
    #       - debugger:      { in: seque, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> <Lingo|?>
    #   out> <kann = [(koennen/v)]>
    #   out> <indexierung, automatisch|SEQ = [(indexierung, automatisch/q)]>
    #   out> <automatische = [(automatisch/a)]>
    #   out> <Indexierung = [(indexierung/s)]>
    #   out> <und = [(und/w)]>
    #   out> <indexierung, genial|SEQ = [(indexierung, genial/q)]>
    #   out> <geniale = [(genial/a), (genialisch/a)]>
    #   out> <Indexierung = [(indexierung/s)]>
    #   out> :./PUNC:
    #   out> *EOL('test.txt')
    #   out> *EOF('test.txt')
    #++

    class Sequencer < BufferedAttendee

      UNK = %w[#]
      NUM = %w[0]

      CLS = /[[:alpha:]#{NUM.join}]/o

      def init
        @stopper = get_ary('stopper', DEFAULT_SKIP)
                     .push(WA_UNKNOWN, WA_UNKMULPART)

        @mwc = get_key('multiword', LA_MULTIWORD)
        @cls = []

        @seq = get_key('sequences').map { |str, fmt|
          @cls.concat(cls = (str = str.downcase).scan(CLS))

          (str =~ /\W/ ? [Regexp.new(str), nil] : [str, cls]).push(
            fmt == true ? '|' : fmt ? fmt.gsub(/\d+/, '%\&$s') : nil)
        }

        @cls.uniq!

        raise MissingConfigError.new(:sequences) if @seq.empty?
      end

      def control(cmd, *)
        process_buffer if [:RECORD, :EOF].include?(cmd)
      end

      def process_buffer?
        (obj = @buffer.last).is_a?(WordForm) && @stopper.include?(obj.attr)
      end

      def process_buffer
        flush(@buffer.size < 2 ? @buffer : begin
          arg = [[], buf = [], map = [], @seq]

          iter, skip, rewind = @buffer.each_with_index, 0, lambda {
            iter.rewind; skip.times { iter.next }; skip = 0
          }

          loop {
            obj, idx = begin
              iter.next
            rescue StopIteration
              raise unless skip > 0

              buf.slice!(0, skip)
              map.slice!(0, skip)

              rewind.call
            end

            att = (tok = obj.is_a?(Token)) ? obj.number? ? NUM : UNK :
              obj.is_a?(Word) && !obj.unknown? ? obj.compound_attrs : UNK

            if (att &= @cls).empty?
              find_seq(*arg)
              rewind.call if skip > 0
            else
              obj.each_lex(@mwc) { |lex|
                lex.form.count(' ').succ.times { iter.next }
                break skip = idx + 1
              } unless tok

              buf << obj
              map << att
            end
          }

          @buffer.concat(find_seq(*arg))
        end)
      end

      private

      def find_seq(mat, buf, map, seq)
        return mat if buf.empty?

        forms, args = [], []

        map.replace(map.shift.product(*map)).map! { |i| i.join }.uniq!

        map.each { |q|
          seq.each { |str, cls, fmt|
            _str, _cls = [str, cls]

            while pos = q.index(str, pos || 0)
              _str, _cls = [$&, $&.chars] unless cls

              _tok = nil; args.clear

              _cls.each_with_index { |wc, i|
                obj = buf[pos + i];_tok ||= obj.token

                args[i] = obj.is_a?(Word) ? obj.lexicals.find { |lex|
                  break lex.form if lex.attr == wc } : obj.form or break
              } or next

              forms << [_str, _tok,
                fmt =~ /\d/ ? fmt.gsub('%0$s', _str) % args :
                fmt ? "#{_str}:#{args.join(fmt)}" : args.join(' ')]

              pos += 1
            end
          }
        }.clear

        forms.uniq!

        forms.each { |s, t, f|
          wrd = Word.new_lexical(f, WA_SEQUENCE, LA_SEQUENCE)
          wrd.pattern, wrd.token = s, t
          mat << wrd
        }

        buf.clear
        mat
      end

    end

  end

end
