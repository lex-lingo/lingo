# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2016 John Vorhauer, Jens Wille                           #
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
    #++

    class TextWriter < self

      include TextUtils

      def init
        @encoding = get_enc

        @ext = get_key('ext', 'txt2')
        @lir = get_key('lir-format', false)

        @sep = get_key('sep', nil) unless @lir
        @sep &&= @sep.evaluate
        @sep ||= ' '

        @no_sep, @no_puts = true, false
      end

      def control(cmd, param = nil, *)
        case cmd
          when :LIR
            @lir = true unless @lir.nil?
          when :FILE
            @no_sep, @io = true, (@stdout = stdout?(@ext)) ?
              open_stdout : open_path(get_path(param, @ext), 'w')

            @lir_rec_no, @lir_rec_buf = '', []
          when :RECORD
            if @lir
              @no_sep = true

              flush_lir_buffer
              @lir_rec_no = param
            end
          when :EOL
            @no_sep = true
            @io.puts unless @lir || @no_puts
          when :EOF
            flush_lir_buffer if @lir
            @io.close unless @stdout
        end
      end

      def process(obj)
        obj = obj.form if obj.is_a?(WordForm)

        @lir ? @lir_rec_buf << obj : begin
          @no_sep ? @no_sep = false : @io.print(@sep)
          @io.print(obj)
        end
      end

      private

      def flush_lir_buffer
        unless @lir_rec_no.empty? || @lir_rec_buf.empty?
          buf = [@lir_rec_no, @lir_rec_buf.join(@sep), "\n"]
          @sep =~ /\n/ ? buf.insert(1, "\n").unshift('*') : buf.insert(1, '*')
          @io.print(*buf)
        end

        @lir_rec_no = ''
        @lir_rec_buf.clear
      end

    end

  end

end
