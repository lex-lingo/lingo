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

      PROTO = '(?:news|https?|ftps?)://'

      RULES = [
        ['SPAC', /^\s+/],
        ['WIKI', /^=+.+=+|^__[A-Z]+__/],
        ['NUMS', /^[+-]?(?:\d{4,}|\d{1,3}(?:\.\d{3,3})*)(?:\.|(?:,\d+)?%?)/],
        ['URLS', /^(?:www\.|mailto:|#{PROTO}|\S+?[._]\S+?@\S+?\.)[^\s<>]+/],
        ['ABRV', /^(?:(?:(?:#{CHAR})+\.)+)(?:#{CHAR})+/],
        ['WORD', /^(?:#{CHAR}|#{DIGIT}|-)+/],
        ['PUNC', /^[!,.:;?¡¿]+/]
      ]

      OTHER = [
        ['OTHR', /^["$#%&'()*+\/<=>@\[\\\]^_{|}~¢£¤¥¦§¨©«¬®¯°±²³´¶·¸¹»¼½¾×÷„“–]/],
        ['HELP', /^\S+/]
      ]

      NESTS = {
        'HTML'          => ['<',   '>'],
        'WIKI:VARIABLE' => ['{{{', '}}}'],
        'WIKI:TEMPLATE' => ['{{',  '}}'],
        'WIKI:LINK_INT' => ['[[',  ']]'],
        'WIKI:LINK_EXT' => [/^\[\s*#{PROTO}/, ']']
      }

      class << self

        def rule(name)
          RULES.assoc(name)
        end

        def rules(name)
          RULES.select { |rule,| rule == name }
        end

        def delete(*names)
          names.map { |name| rules(name).each { |rule| RULES.delete(rule) } }
        end

        def replace(name, expr = nil)
          rules(name).each { |rule| rule[1] = expr || yield(*rule) }
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

        @skip_tags = get_array('skip-tags', '', :downcase)
        @tags = true unless @skip_tags.empty?

        skip = []
        skip << 'HTML' unless @tags
        skip << 'WIKI' unless @wiki

        [@rules = RULES.dup, @nests = NESTS.dup].each { |hash|
          hash.delete_if { |name, _| skip.include?(Token.clean(name)) }
        }

        @override, @nest, nest_re = [], [], []

        @nests.each { |name, re|
          re.map!.with_index { |r, i| r.is_a?(Regexp) ?
            r : /^#{'.*?' if i > 0}#{Regexp.escape(r)}/ }

          nest_re << "(?<#{name}>#{Regexp.new(
            re[0].source.sub(/^\^/, ''), re[0].options)})"
        }

        @nest_re = /^(?<_>.*?)(?:#{nest_re.join('|')})/

        reset
      end

      def control(cmd, filename = nil, *)
        case cmd
          when :FILE then reset(filename)
          when :LIR  then reset(nil, nil)
          when :EOL  then @linenum += 1 if @linenum
          when :EOF  then @override.clear; @nest.clear
        end
      end

      def process(line, offset)
        @offset = offset
        tokenize(line)
        command(:EOL, @filename) if @filename
      end

      private

      def reset(filename = nil, linenum = 1)
        @filename, @linenum, @position, @offset = filename, linenum, -1, 0
      end

      # tokenize("Eine Zeile.")  ->  [:Eine/WORD:, :Zeile/WORD:, :./PUNC:]
      def tokenize(line)
        @nest.empty? ? tokenize_line(line) : tokenize_nest(line)
      rescue => err
        raise err if err.is_a?(TokenizeError)
        raise TokenizeError.new(line, @filename, @linenum, err)
      end

      def tokenize_line(line)
        while (length = line.length) > 0 && tokenize_rule(line) { |rest|
          length == rest.length ? break : line = rest
        }
        end

        tokenize_open(line) unless line.empty?
      end

      def tokenize_rule(line, rules = @rules)
        rules.find { |name, expr|
          next unless line =~ expr

          rest = $'
          forward_token($&, name, rest) if name != 'SPAC' || @space

          yield rest
        }
      end

      def tokenize_nest(line)
        mdo = @nest_re.match(line)
        mdc = @nests[@nest.last].last.match(line)

        if mdo && (!mdc || mdo[0].length < mdc[0].length)
          rest = mdo.post_match
          nest = @nests.keys.find { |name| mdo[name] }
          text = mdo[nest]
          lead = mdo[:_]

          forward_token(lead, @nest.last, text + rest) unless lead.empty?

          forward_nest(text, nest, rest)
        elsif mdc
          rest = mdc.post_match
          nest = @nest.pop
          text = mdc[0]

          forward_token(text, nest, rest)

          if overriding?(nest)
            @override.pop if text.downcase.end_with?("/#{@override.last}>")
          end

          tokenize(rest)
        else
          forward_token(line, @nest.last)
        end
      end

      def tokenize_open(line)
        @nests.each { |nest, (open_re, _)|
          next unless line =~ open_re
          return forward_nest($&, nest, $')
        }

        tokenize_rule(line, OTHER) { |rest| line = rest }
        tokenize(line)
      end

      def forward_nest(match, nest, rest)
        if overriding?(nest)
          tag = rest[/^[^\s>]*/].downcase
          @override << tag if @skip_tags.include?(tag)
        end

        forward_token(match, nest, rest)

        @nest << nest
        tokenize(rest)
      end

      def forward_token(form, attr, rest = '')
        forward(Token.new(form, @override.empty? ? attr : 'SKIP',
          @position += 1, @offset - form.bytesize - rest.bytesize))
      end

      def overriding?(nest)
        nest == 'HTML' && !@skip_tags.empty?
      end

    end

  end

end
