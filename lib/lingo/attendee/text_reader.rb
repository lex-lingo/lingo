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

require 'find'

%w[filemagic mime/types nokogiri nuggets/file/which pdf-reader].each { |lib|
  begin
    require lib
  rescue LoadError
  end
}

class Lingo

  class Attendee

    #--
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
    #++

    class TextReader < self

      # TODO: FILE/LIR-FILE (?)
      def init
        get_files

        @encoding = get_enc

        @filter   = get_key('filter', false)
        @progress = get_key('progress', false)

        if has_key?('lir-record-pattern')
          lingo.config.deprecate('lir-record-pattern', :records, self)
        end

        @lir  = get_re('records', get_key('lir-record-pattern', nil), %r{^\[(\d+)\.\]})  # DEPRECATE lir-record-pattern
        @cut  = get_re('fields', !!@lir, %r{^.+?:\s*})
        @skip = get_re('skip', nil)
      end

      def control(cmd, *)
        return unless cmd == :TALK

        command(:LIR) if @lir

        @files.each { |path|
          command(:FILE, path)

          io = !stdin?(path) ? open_file(name = path) : begin
            stdin = lingo.config.stdin.set_encoding(@encoding)
            @progress ? StringIO.new(stdin.read) : stdin
          end

          Progress.new(self, @progress && io.size, name) { |progress|
            pos = 0 unless pos?(io = filter(io, path, progress))

            io.each { |line|
              progress << offset = pos ? pos += line.bytesize : io.pos

              line =~ @skip ? nil : line =~ @lir ?
                command(:RECORD, $1 || $&) : begin
                  line.sub!(@cut, '') if @cut
                  forward(line, offset) unless line.empty?
                end
            }
          }

          command(:EOF, path)
        }

        command(:EOT)
        :skip_command
      end

      private

      def filter(io, path, progress)
        case @filter == true ? file_type(io, path) : @filter.to_s
          when 'pdftotext' then filter_pdftotext(io, path, progress)
          when /html/i     then filter_html(io)
          when /xml/i      then filter_html(io, true)
          when /pdf/i      then filter_pdf(io)
          else io
        end
      end

      def filter_pdftotext(io, path, progress, name = 'pdftotext')
        cancel_filter(:PDF, name, :command) unless cmd = File.which(name)

        with_tempfile(name) { |tempfile|
          pdf_path = stdin?(path) ? tempfile[:pdf, io] : path
          system(cmd, '-q', pdf_path, txt_path = tempfile[:txt])

          progress.init(File.size(txt_path)) if @progress
          open_file(txt_path)
        }
      end

      def filter_pdf(io)
        Object.const_defined?(:PDF) && PDF.const_defined?(:Reader) ? text_enum(
          PDF::Reader.new(io).pages) : cancel_filter(:PDF, 'pdf-reader')
      end

      def filter_html(io, xml = false, type = xml ? :XML : :HTML)
        Object.const_defined?(:Nokogiri) ? text_enum(Nokogiri.send(type,
          io, nil, @encoding).children) : cancel_filter(type, :nokogiri)
      end

      def file_type(io, path)
        Object.const_defined?(:FileMagic) && io.respond_to?(:rewind) ?
          FileMagic.fm(:mime, simplified: true).io(io, 256).tap { io.rewind } :
        Object.const_defined?(:MIME) && MIME.const_defined?(:Types) ?
          (type = MIME::Types.of(path).first) ? type.content_type :
          cancel_filters('File type could not be determined.') :
          cancel_filters(please_install(:gem, 'ruby-filemagic', 'mime-types'))
      end

      def cancel_filters(msg)
        cancel("Filters not available. #{msg}")
      end

      def cancel_filter(type, name, what = :gem)
        cancel("#{type} filter not available. #{please_install(what, name)}")
      end

      def please_install(what, *names)
        "Please install the `#{names.join("' or `")}' #{what}."
      end

      def cancel(msg)
        throw(:cancel, msg)
      end

      def stdin?(path)
        %w[STDIN -].include?(path)
      end

      def pos?(io)
        io.pos if io.respond_to?(:pos)
      rescue Errno::ESPIPE
      end

      def open_file(path)
        File.open(path, 'rb', encoding: @encoding)
      end

      def with_tempfile(name)
        require 'tempfile'

        tempfiles = []

        yield lambda { |ext, io = nil|
          tempfiles << temp = Tempfile.new([name, ".#{ext}"])
          temp.write(io.read) if io
          temp.close
          temp.path
        }
      ensure
        tempfiles.each(&:unlink)
      end

      def text_enum(collection)
        Enumerator.new { |y| collection.each { |x| y << x.text } }
      end

      def get_files
        args = [get_key('glob', '*.txt'), get_key('recursive', false)]

        @files = []

        Array(get_key('files', '-')).each { |path| stdin?(path) ?
          @files << path : add_files(File.expand_path(path), *args) }
      end

      def add_files(path, glob, recursive = false)
        raise FileNotFoundError.new(path) if (entries = Dir[path]).sort!.empty?

        entries.each { |entry|
          !File.directory?(entry) ? @files << entry : !recursive ?
            add_files(File.join(entry, glob), glob) : Find.find(entry) { |match|
              @files << match if File.file?(match) && File.fnmatch?(glob, match) } }
      end

    end

    # For backwards compatibility.
    Textreader  = TextReader
    Text_reader = TextReader

  end

end
