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

require 'find'

%w[filemagic mime/types hpricot pdf-reader].each { |lib|
  begin
    require lib
  rescue LoadError
  end
}

class Lingo

  class Attendee

    # Der TextReader ist eine klassische Datenquelle. Er liest eine oder mehrere Dateien
    # und gibt sie Zeilenweise in den Ausgabekanal. Der Start bzw. Wechsel einer Datei
    # wird dabei über den Kommandokanal angekündigt, ebenso wie das Ende.
    #
    # Der TextReader kann ebenfalls ein spezielles Dateiformat verarbeiten, welches zum
    # Austausch mit dem LIR-System dient. Dabei enthält die Datei Record-basierte Informationen,
    # die wie mehrere Dateien verarbeitet werden.
    #
    # === Mögliche Verlinkung
    # Erzeugt:: Daten des Typs *String* (Textzeile) z.B. für Tokenizer, Textwriter
    #
    # === Parameter
    # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
    # Alle anderen Parameter müssen zwingend angegeben werden.
    # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
    # <b>files</b>:: Es können eine oder mehrere Dateien angegeben werden, die nacheinander
    #                eingelesen und zeilenweise weitergeleitet werden. Die Dateien werden mit
    #                Komma voneinander getrennt, z.B.
    #                  files: 'readme.txt'
    #                  files: 'readme.txt,lingo.cfg'
    # <b><i>records</i></b>:: Mit diesem Parameter wird angegeben, woran der Anfang
    #                         eines neuen Records erkannt werden kann und wie die
    #                         Record-Nummer identifiziert wird. Das Format einer
    #                         LIR-Datei ist z.B.
    #                           [00001.]
    #                           020: ¬Die Aufgabenteilung zwischen Wortschatz und Grammatik.
    #
    #                           [00002.]
    #                           020: Nicht-konventionelle Thesaurusrelationen als Orientierungshilfen.
    #                         Mit der Angabe von
    #                           records: "^\[(\d+)\.\]"
    #                         werden die Record-Zeilen erkannt und jeweils die Record-Nummer +00001+,
    #                         bzw. +00002+ erkannt.
    #
    # === Generierte Kommandos
    # Damit der nachfolgende Datenstrom einwandfrei verarbeitet werden kann, generiert der TextReader
    # Kommandos, die mit in den Datenstrom eingefügt werden.
    # <b>*FILE(<dateiname>)</b>:: Kennzeichnet den Beginn der Datei <dateiname>
    # <b>*EOF(<dateiname>)</b>:: Kennzeichnet das Ende der Datei <dateiname>
    # <b>*LIR_FORMAT('')</b>:: Kennzeichnet die Verarbeitung einer Datei im LIR-Format (nur bei LIR-Format).
    # <b>*RECORD(<nummer>)</b>:: Kennzeichnet den Beginn eines neuen Records (nur bei LIR-Format).
    # === Beispiele
    # Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader: { out: lines, files: '$(files)' }
    #       - debugger:    { in: lines, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> "Dies ist eine Zeile."
    #   out> "Dies ist noch eine."
    #   out> *EOF('test.txt')
    # Bei der Verarbeitung einer LIR-Datei mit der Ablaufkonfiguration <tt>t2.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader: { out: lines,  files: '$(files)', records: "^\[(\d+)\.\]" }
    #       - debugger:    { in: lines, prompt: 'out>'}
    # ergibt die Ausgabe mit <tt>lingo -c t2 lir.txt</tt>
    #   out> *LIR-FORMAT('')
    #   out> *FILE('lir.txt')
    #   out> *RECORD('00001')
    #   out> "020: \254Die Aufgabenteilung zwischen Wortschatz und Grammatik."
    #   out> *RECORD('00002')
    #   out> "020: Nicht-konventionelle Thesaurusrelationen als Orientierungshilfen."
    #   out> *EOF('lir.txt')

    class TextReader < self

      protected

      # TODO: FILE und LIR-FILE (?)
      def init
        get_files

        @chomp    = get_key('chomp', true)
        @filter   = get_key('filter', false)
        @progress = get_key('progress', false)

        if @lir = get_key('records', get_key('lir-record-pattern', nil))  # DEPRECATE lir-record-pattern
          @lir = @lir == true ? %r{^\[(\d+)\.\]} : Regexp.new(@lir)
        end
      end

      def control(cmd, param)
        if cmd == STR_CMD_TALK
          forward(STR_CMD_LIR, '') if @lir
          @files.each(&method(:spool))
        end
      end

      private

      # Gibt eine Datei zeilenweise in den Ausgabekanal
      def spool(path)
        unless stdin = stdin?(path)
          inc('Anzahl Dateien')
          add('Anzahl Bytes', size = File.size(path))

          size = nil unless @progress
        end

        forward(STR_CMD_FILE, path)

        ShowProgress.new(self, size, path) { |progress|
          filter(path, stdin) { |line, pos|
            inc('Anzahl Zeilen')
            progress[pos]

            line.chomp! if @chomp

            if line =~ @lir
              forward(STR_CMD_RECORD, $1)
            else
              forward(line) unless line.empty?
            end
          }
        }

        forward(STR_CMD_EOF, path)
      end

      def filter(path, stdin = stdin?(path))
        io, block = stdin ? [
          @lingo.config.stdin.set_encoding(ENC),
          lambda { |line| yield line, 0 }
        ] : [
          File.open(path, 'rb', encoding: ENC),
          lambda { |line| yield line, io.pos }
        ]

        case @filter == true ? file_type(path, io) : @filter.to_s
          when /html/i then io = filter_html(io)
          when /xml/i  then io = filter_html(io, true)
          when /pdf/i  then filter_pdf(io, &block); return
        end

        io.each_line(&block) if io
      end

      def filter_pdf(io, &block)
        if Object.const_defined?(:PDF) && PDF.const_defined?(:Reader)
          PDFFilter.filter(io, &block)
        else
          warn "PDF filter not available. Please install `pdf-reader'."
        end
      end

      def filter_html(io, xml = false)
        if Object.const_defined?(:Hpricot)
          Hpricot(io, xml: xml).inner_text
        else
          warn "#{xml ? 'X' : 'HT'}ML filter not available. Please install `hpricot'."
          nil
        end
      end

      def file_type(path, io)
        if Object.const_defined?(:FileMagic) && io.respond_to?(:rewind)
          FileMagic.fm(:mime, simplified: true).buffer(io.read(256)).tap {
            io.rewind
          }
        elsif Object.const_defined?(:MIME) && MIME.const_defined?(:Types)
          MIME::Types.of(path).first.tap { |type| type ? type.content_type :
            warn('Filters not available. File type could not be determined.')
          }
        else
          warn "Filters not available. Please install `ruby-filemagic' or `mime-types'."
          nil
        end
      end

      def stdin?(path)
        %w[STDIN -].include?(path)
      end

      def get_files
        args = [get_key('glob', '*.txt'), get_key('recursive', false)]

        @files = []

        Array(get_key('files', '-')).each { |path|
          stdin?(path) ? @files << path : add_files(path, *args)
        }
      end

      def add_files(path, glob, recursive = false)
        entries = Dir[path].sort!
        raise FileNotFoundError.new(path) if entries.empty?

        entries.each { |entry|
          if File.directory?(entry)
            if recursive
              Find.find(entry) { |match|
                if File.file?(match) && File.fnmatch?(glob, match)
                  @files << File.expand_path(match)
                end
              }
            else
              add_files(File.join(entry, glob), glob)
            end
          else
            @files << File.expand_path(entry)
          end
        }
      end

      class PDFFilter

        def self.filter(io, &block)
          PDF::Reader.new.parse(io, new(&block))
        end

        def initialize(&block)
          @block = block
        end

        def show_text(string, *params)
          @block[string << '|']
        end

        alias_method :super_show_text,                 :show_text
        alias_method :move_to_next_line_and_show_text, :show_text
        alias_method :set_spacing_next_line_show_text, :show_text

        def show_text_with_positioning(params, *)
          params.each { |param| show_text(param) if param.is_a?(String) }
        end

      end

    end

    # For backwards compatibility.
    Textreader  = TextReader
    Text_reader = TextReader

  end

end
