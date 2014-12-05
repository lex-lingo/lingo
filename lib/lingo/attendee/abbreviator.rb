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
    # Die Erkennung von Abkürzungen kann auf vielfältige Weise erfolgen. In jedem Fall
    # sollte eine sichere Unterscheidung von einem Satzende-Punkt möglich sein.
    # Der in Lingo gewählte Ansatz befreit den Tokenizer von dieser Arbeit und konzentriert
    # die Erkennung in diesem Attendee.
    # Sobald der Abbreviator im Datenstrom auf ein Punkt trifft (Token = <tt>:./PUNC:</tt>),
    # prüft er das vorhergehende Token auf eine gültige Abkürzung im Abkürzungs-Wörterbuch.
    # Wird es als Abkürzung erkannt, dann wird das Token in ein Word gewandelt und das
    # Punkt-Token aus dem Zeichenstrom entfernt.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten des Typs *Token* z.B. von Tokenizer
    # Erzeugt:: Leitet Token weiter und wandelt erkannte Abkürzungen in den Typ *Word* z.B. für Wordsearcher
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
    #       - text_reader:  { out: lines, files: '$(files)' }
    #       - tokenizer:    { in: lines, out: token }
    #       - abbreviator:  { in: token, out: abbrev, source: 'sys-abk' }
    #       - debugger:     { in: abbrev, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> :Dies/WORD:
    #   out> :ist/WORD:
    #   out> <ggf. = [(gegebenenfalls/w)]>
    #   out> :eine/WORD:
    #   out> :Abk³rzung/WORD:
    #   out> :./PUNC:
    #   out> *EOL('test.txt')
    #   out> *EOF('test.txt')
    #++

    class Abbreviator < self

      def init
        set_dic
        @abbr = nil
      end

      def control(cmd, *)
        send_abbr(@abbr) if [:RECORD, :EOF].include?(cmd)
      end

      def process(obj)
        if obj.is_a?(Token)
          if obj.form == CHAR_PUNCT
            if @abbr && (abbr = find_word(form = @abbr.form)).identified?
              form << CHAR_PUNCT unless form.end_with?(CHAR_PUNCT)
              send_abbr(abbr)
            else
              send_abbr(@abbr)
              forward(obj)
            end
          else
            send_abbr(@abbr, obj)
          end
        else
          send_abbr(obj)
        end
      end

      private

      def send_abbr(abbr, obj = nil)
        @abbr = obj
        forward(abbr) if abbr
      end

    end

  end

end
