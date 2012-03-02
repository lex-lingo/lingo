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

    # Der TextWriter ermöglicht die Umleitung des Datenstroms in eine Textdatei. Dabei werden
    # Objekte, die nicht vom Typ String sind in eine sinnvolle Textrepresentation gewandelt.
    # Der Name der Ausgabedatei wird durch den Namen der Eingabedatei (des Textreaders) bestimmt.
    # Es kann lediglich die Extension verändert werden. Der TextWriter kann auch das LIR-Format
    # erzeugen.
    #
    # === Mögliche Verlinkung
    # Erwartet:: Daten verschiedenen Typs
    #
    # === Parameter
    # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
    # Alle anderen Parameter müssen zwingend angegeben werden.
    # <b>in</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
    # <b><i>ext</i></b>:: (Standard: txt2) Gibt die Dateinamen-Erweiertung für die Ausgabedatei an.
    #                     Wird z.B. dem TextReader die Datei <tt>Dokument.txt</tt> angegeben und
    #                     über die Lingo-Konfiguration alle Indexwörter herausgefiltert, kann mit
    #                     <tt>ext: 'idx'</tt> der TextWriter veranlasst werden, die Indexwörter in
    #                     die Datei <tt>Dokument.idx</tt> zu schreiben.
    # <b><i>sep</i></b>:: (Standard: ' ') Gibt an, mit welchem Trennzeichen zwei aufeinanderfolgende
    #                     Objekte in der Ausgabedatei getrennt werden sollen. Gängige Werte sind auch
    #                     noch '\n', welches die Ausgabe jedes Objektes in eine Zeile ermöglicht.
    # <b><i>lir-format</i></b>:: (Standard: false) Dieser Parameter hat keinen Wert. Wird er angegeben,
    #                            dann wird er als true ausgewertet. Damit ist es möglich, die Ausgabedatei
    #                            im für LIR lesbarem Format zu erstellen.
    #
    # === Beispiele
    # Bei der Verarbeitung der oben angegebenen Funktionsbeschreibung des Textwriters mit der Ablaufkonfiguration <tt>t1.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader:    { out: lines, files: '$(files)' }
    #       - tokenizer:      { in: lines, out: token }
    #       - word_searcher:  { in: token, out: words, source: 'sys-dic' }
    #       - vector_filter:  { in: words, out: filtr, sort: 'term_rel' }
    #       - text_writer:    { in: filtr, ext: 'vec', sep: '\n' }
    # ergibt die Ausgabe in der Datei <tt>test.vec</tt>
    #   0.03846 name
    #   0.01923 ausgabedatei
    #   0.01923 datenstrom
    #   0.01923 extension
    #   0.01923 format
    #   0.01923 objekt
    #   0.01923 string
    #   0.01923 textdatei
    #   0.01923 typ
    #   0.01923 umleitung

    class TextWriter < self

      protected

      def init
        @ext = get_key('ext', 'txt2')
        @lir = get_key('lir-format', false)

        @sep   = @config['sep'] unless @lir
        @sep &&= @sep.evaluate
        @sep ||= ' '

        @no_sep, @no_puts = true, false
      end

      def control(cmd, param)
        case cmd
          when STR_CMD_LIR
            @lir = true
          when STR_CMD_FILE
            @no_sep = true

            if stdout?(@ext)
              @filename, @file = @ext, @lingo.config.stdout
            else
              inc('Anzahl Dateien')
              @file = File.open(@filename = File.set_ext(param, ".#{@ext}"), 'w')
            end

            @lir_rec_no, @lir_rec_buf = '', []
          when STR_CMD_RECORD
            @no_sep = true

            if @lir
              flush_lir_buffer
              @lir_rec_no = param
            end
          when STR_CMD_EOL
            @no_sep = true

            unless @lir
              inc('Anzahl Zeilen')
              @file.puts unless @no_puts
            end
          when STR_CMD_EOF
            flush_lir_buffer if @lir

            unless stdout?(@filename)
              add('Anzahl Bytes', @file.size)
              @file.close
            end
        end
      end

      def process(obj)
        obj = obj.form if obj.is_a?(WordForm)

        @lir ? @lir_rec_buf << obj : begin
          @no_sep ? @no_sep = false : @file.print(@sep)
          @file.print(obj)
        end
      end

      private

      def flush_lir_buffer
        unless @lir_rec_no.empty? || @lir_rec_buf.empty?
          @file.print(*[@lir_rec_no, @lir_rec_buf.join(@sep), "\n"].tap { |buf|
            @sep =~ /\n/ ? buf.insert(1, "\n").unshift('*') : buf.insert(1, '*')
          })
        end

        @lir_rec_no = ''
        @lir_rec_buf.clear
      end

      def stdout?(filename)
        %w[STDOUT -].include?(filename)
      end

    end

    # For backwards compatibility.
    Textwriter  = TextWriter
    Text_writer = TextWriter

  end

end
