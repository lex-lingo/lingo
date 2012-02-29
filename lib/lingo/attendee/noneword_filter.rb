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

    # Der NonewordFilter ermöglicht es, alle nicht erkannten Wörter aus dem Datenstrom zu
    # selektieren und weiterzuleiten. Im Prinzip werden alle erkannten Wörter gefiltert.
    # Bei einem Indexierungslauf können so alle nicht durch den Wordsearcher erkannten Wörter,
    # also die, die im Wörterbuch nicht enthalten sind, separat ausgegeben werden und als Grundlage für
    # die Wörterbuchpflege dienen.
    # Der NonewordFilter ist in einer frühen Entwicklungsphase entstanden. Die gleiche Funktion
    # kann auch mit dem universelleren Objectfilter mit dem Ausdruck 'obj.kind_of?(Word) && obj.attr==WA_UNKNOWN'
    # durchgeführt werden, mit dem einzigen Unterschied, dass der NonewordFilter nur die Wortform weiterleitet.
    # Der NonewordFilter verschluckt ebenfalls alle Kommandos, ausser dem Dateianfang (*FILE) und Ende (*EOF),
    # sowie dem LIR-Format-Spezifikum (*RECORD).
    #
    # *Hinweis* Dieser Attendee sammelt die auszugebenden Daten so lange, bis ein Dateiwechsel oder Record-Wechsel
    # angekündigt wird. Erst dann werden alle Daten auf einmal weitergeleitet.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten vom Typ *Word*, z.B. von Abbreviator, Wordsearcher, Decomposer, Synonymer, Multiworder, Sequencer
    # Erzeugt:: Daten vom Typ *String*, z.B. für Textwriter
    #
    # === Parameter
    # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
    # Alle anderen Parameter müssen zwingend angegeben werden.
    # <b>in</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
    #
    # === Beispiele
    # Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader:      { out: lines, files: '$(files)' }
    #       - tokenizer:        { in: lines, out: token }
    #       - word_searcher:    { in: token, out: words, source: 'sys-dic' }
    #       - noneword_filter:  { in: words, out: filtr }
    #       - debugger:         { in: filtr, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> "lingo"
    #   out> *EOF('test.txt')

    class NonewordFilter < self

      protected

      def init
        @nonewords, @sort = [], get_key('sort', true)
      end

      def control(cmd, param)
        case cmd
          when STR_CMD_FILE
            @nonewords.clear
          when STR_CMD_EOL
            skip_command
          when STR_CMD_RECORD, STR_CMD_EOF
            send_nonewords unless @nonewords.empty?
        end
      end

      def process(obj)
        if obj.is_a?(Word) && obj.unknown?
          inc('Anzahl nicht erkannter Wörter')

          non = obj.form.downcase
          @sort ? @nonewords << non : forward(non)
        end
      end

      private

      def send_nonewords
        @nonewords.sort!
        @nonewords.uniq!

        add('Objekte gefiltert', @nonewords.size)
        @nonewords.each(&method(:forward)).clear
      end

    end

    # For backwards compatibility.
    Nonewordfilter  = NonewordFilter
    Noneword_filter = NonewordFilter

  end

end
