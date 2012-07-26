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

    # Der Tokenizer zerlegt eine Textzeile in einzelne Token. Dies ist notwendig,
    # damit nachfolgende Attendees die Textdatei häppchenweise verarbeiten können.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten des Typs *String* (Textzeilen) z.B. von TextReader
    # Erzeugt:: Daten des Typs *Token* z.B. für Abbreviator, Wordsearcher
    #
    # === Parameter
    # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
    # Alle anderen Parameter müssen zwingend angegeben werden.
    # <b>in</b>:: siehe allgemeine Beschreibung des Attendee.
    # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
    #
    # === Konfiguration
    # Der Tokenizer benötigt zur Identifikation einzelner Token Regeln, nach denen er
    # arbeiten soll. Die benötigten Regeln werden aufgrund des Umfangs nicht als Parameter,
    # sondern in einer Programmkonstanten hinterlegt.
    # Die Regeln werden in der angegebenen Reihenfolge abgearbeitet, solange bis ein Token
    # erkannt wurde. Sollte keine Regel zutreffen, so greift die letzt Regel +HELP+ in jedem
    # Fall.
    #
    # === Generierte Kommandos
    # Damit der nachfolgende Datenstrom einwandfrei verarbeitet werden kann, generiert der Tokenizer
    # Kommandos, die mit in den Datenstrom eingefügt werden.
    # <b>*EOL(<dateiname>)</b>:: Kennzeichnet das Ende einer Textzeile, da die Information ansonsten
    # für nachfolgende Attendees verloren wäre.
    #
    # === Beispiele
    # Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader: { out: lines, files: '$(files)' }
    #       - tokenizer:   { in: lines, out: token }
    #       - debugger:    { in: token, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> :Dies/WORD:
    #   out> :ist/WORD:
    #   out> :eine/WORD:
    #   out> :Zeile/WORD:
    #   out> :./PUNC:
    #   out> *EOL('test.txt')
    #   out> :Dies/WORD:
    #   out> :ist/WORD:
    #   out> :noch/WORD:
    #   out> :eine/WORD:
    #   out> :./PUNC:
    #   out> *EOL('test.txt')
    #   out> *EOF('test.txt')

    class Tokenizer < self

      CHAR, DIGIT = Char::CHAR, Char::DIGIT

      RULES = [
        ['WIKI', /^=+.+=+$/],
        ['SPAC', /^\s+/],
        ['HTML', /^<[^>]+>/],
        ['WIKI', /^\[\[.+?\]\]/],
        ['NUMS', /^[+-]?(?:\d{4,}|\d{1,3}(?:\.\d{3,3})*)(?:\.|(?:,\d+)?%?)/],
        ['URLS', /^(?:(?:mailto:|(?:news|https?|ftps?):\/\/)\S+|^(?:www(?:\.\S+)+)|[^\s.]+(?:[\._]\S+)+@\S+(?:\.\S+)+)/],
        ['ABRV', /^(?:(?:(?:#{CHAR})+\.)+)(?:#{CHAR})+/],
        ['WORD', /^(?:#{CHAR}|#{DIGIT}|-)+/],
        ['PUNC', /^[!,.:;?¡¿]/],
        ['OTHR', /^["$#%&'()*+\-\/<=>@\[\\\]^_{|}~¢£¤¥¦§¨©«¬®¯°±²³´¶·¸¹»¼½¾×÷]/],
        ['HELP', /^[^ ]*/]
      ]

      class << self

        def rule(name)
          RULES.assoc(name)
        end

        def delete(*names)
          names.each { |name| RULES.delete(rule(name)) }
        end

        def replace(name, expr)
          rule = rule(name) or return
          rule[1] = block_given? ? yield(rule[1]) : expr
        end

        def insert(*rules)
          _insert(0, rules)
        end

        def append(*rules)
          _insert(-1, rules)
        end

        def insert_before(name, *rules)
          _insert_name(name, rules, 0)
        end

        def insert_after(name, *rules)
          _insert_name(name, rules, -1)
        end

        private

        def _insert(index, rules)
          rules.push(*rules.pop) if rules.last.is_a?(Hash)
          RULES.insert(index, *rules)
        end

        def _insert_name(name, rules, offset)
          index = RULES.index(rule(name))
          _insert(index ? index - offset : offset, rules)
        end

      end

      protected

      def init
        @space = get_key('space', false)
        @tags  = get_key('tags',  false)
        @wiki  = get_key('wiki',  false)

        skip = []
        skip << 'HTML' unless @tags
        skip << 'WIKI' unless @wiki

        @rules = RULES.reject { |name, _| skip.include?(name) }

        @filename = @cont = nil
      end

      def control(cmd, param)
        case cmd
          when STR_CMD_FILE then @filename = param
          when STR_CMD_LIR  then @filename = nil
          when STR_CMD_EOF  then @cont     = nil
        end
      end

      def process(obj)
        if obj.is_a?(String)
          inc('Anzahl Zeilen')

          tokenize(obj) { |form, attr|
            inc("Anzahl Muster #{attr}")
            inc('Anzahl Token')

            forward(Token.new(form, attr))
          }

          forward(STR_CMD_EOL, @filename) if @filename
        else
          forward(obj)
        end
      end

      private

      # tokenize("Eine Zeile.")  ->  [:Eine/WORD:, :Zeile/WORD:, :./PUNC:]
      def tokenize(line)
        case @cont
          when 'HTML'
            if line =~ /^[^<>]*>/
              yield $&, @cont
              line, @cont = $', nil
            else
              yield line, @cont
              return
            end
          when 'WIKI'
            if line =~ /^[^\[\]]*\]\]/
              yield $&, @cont
              line, @cont = $', nil
            else
              yield line, @cont
              return
            end
          when nil
            if @tags && line =~ /<[^<>]*$/
              yield $&, @cont = 'HTML'
              line = $`
            end

            if @wiki && line =~ /\[\[[^\[\]]*$/
              yield $&, @cont = 'WIKI'
              line = $`
            end
        end

        while (l = line.length) > 0 && @rules.find { |name, expr|
          if line =~ expr
            yield $&, name if name != 'SPAC' || @space
            l == $'.length ? break : line = $'
          end
        }
        end
      end

    end

  end

end
