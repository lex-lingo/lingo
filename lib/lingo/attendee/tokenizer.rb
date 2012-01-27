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
    # Erwartet:: Daten des Typs *String* (Textzeilen) z.B. von Textreader
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
    # sondern in der Sprachkonfiguration hinterlegt, die sich standardmäßig in der Datei
    # <tt>de.lang</tt> befindet (YAML-Format).
    #   language:
    #     attendees:
    #       tokenizer:
    #         regulars:
    #           - _CHR_: '\wÄÖÜÁÂÀÉÊÈÍÎÌÓÔÒÚÛÙÝäöüáâàéêèíîìóôòúûùý'
    #           - NUMS:  '[+-]?(\d{4,}|\d{1,3}(\.\d{3,3})*)(\.|(,\d+)?%?)'
    #           - URLS:  '((mailto:|(news|http|https|ftp|ftps)://)\S+|^(www(\.\S+)+)|\S+([\._]\S+)+@\S+(\.\S+)+)'
    #           - ABRV:  '(([_CHR_]+\.)+)[_CHR_]+'
    #           - ABRS:  '(([_CHR_]{1,1}\.)+)(?!\.\.)'
    #           - WORD:  '[_CHR_\d]+'
    #           - PUNC:  '[!,\.:;?]'
    #           - OTHR:  '[!\"#$%&()*\+,\-\./:;<=>?@\[\\\]^_`{|}~´]'
    #           - HELP:  '.*'
    # Die Regeln werden in der angegebenen Reihenfolge abgearbeitet, solange bis ein Token
    # erkannt wurde. Sollte keine Regel zutreffen, so greift die letzt Regel +HELP+ in jedem
    # Fall.
    # Regeln, deren Name in Unterstriche eingefasst sind, werden als Makro interpretiert.
    # Makros werden genutzt, um lange oder sich wiederholende Bestandteile von Regeln
    # einmalig zu definieren und in den Regeln über den Makronamen eine Auflösung zu forcieren.
    # Makros werden selber nicht für die Erkennung von Token eingesetzt.
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
    #       - textreader: { out: lines, files: '$(files)' }
    #       - tokenizer:  { in: lines, out: token }
    #       - debugger:   { in: token, prompt: 'out>' }
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

      protected

      def init
        # Regular Expressions für Token-Erkennung einlesen
        regulars = get_key('regulars', '')
        raise NoConfigKeyError.new(:regulars) unless regulars

        @space = get_key('space', false)
        @tags  = get_key('tags',  true)
        @wiki  = get_key('wiki',  true)

        # default rules
        @rules = [['SPAC', /^\s+/]]
        @rules << ['HTML', /^<[^>]+>/]       unless @tags
        @rules << ['WIKI', /^\[\[.+?\]\]/]   unless @wiki
        @rules.unshift(['WIKI', /^=+.+=+$/]) unless @wiki

        # Mit _xxx_ gekennzeichnete Makros anwenden und Expressions ergänzen und umwandeln
        macros = {}

        regulars.each { |rule|
          name = rule.keys[0]
          expr = rule.values[0].gsub(/_(\w+?)_/) {
            macros[$&] || begin
              Database::Source.const_get("UTF8_#{$1.upcase}")
            rescue NameError
            end
          }

          if name =~ /^_\w+_$/    # is a macro
            macros[name] = expr if name =~ /^_\w+_$/
          else
            @rules << [name, Regexp.new('^'+expr)]
          end
        }

        # Der Tokenizer gibt jedes Zeilenende als Information weiter, sofern es sich
        # nicht um die Verarbeitung einer LIR-Datei handelt. Im Falle einer normalen Datei
        # wird der Dateiname gespeichert und als Kennzeichen für die Erzeugung von
        # Zeilenende-Nachrichten herangezogen.
        @filename = nil
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
            token = Token.new(form, attr)

            inc('Anzahl Muster '+token.attr)
            inc('Anzahl Token')

            forward(token)
          }

          forward(STR_CMD_EOL, @filename) if @filename
        else
          forward(obj)
        end
      end

      private

      # tokenize("Eine Zeile.")  ->  [:Eine/WORD:, :Zeile/WORD:, :./PUNC:]
      def tokenize(textline)
        case @cont
          when 'HTML'
            if textline =~ /^[^<>]*>/
              yield $~[0], @cont
              textline, @cont = $', nil
            else
              yield textline, @cont
              return
            end
          when 'WIKI'
            if textline =~ /^[^\[\]]*\]\]/
              yield $~[0], @cont
              textline, @cont = $', nil
            else
              yield textline, @cont
              return
            end
          when nil
            if !@tags && textline =~ /<[^<>]*$/
              yield $~[0], @cont = 'HTML'
              textline = $`
            end

            if !@wiki && textline =~ /\[\[[^\[\]]*$/
              yield $~[0], @cont = 'WIKI'
              textline = $`
            end
        end

        until textline.empty?
          @rules.each { |name, expr|
            if textline =~ expr
              yield $~[0], name if name != 'SPAC' || @space
              textline = $'
              break
            end
          }
        end
      end

    end

  end

end
