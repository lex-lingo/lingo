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

    # Die Hauptaufgabe des VectorFilter ist die Erstellung eines Dokumenten-Index-Vektor.
    # Dabei werden die durch die anderen Attendees ermittelten Grundformen eines Wortes
    # gespeichert und bei einem Datei- oder Record-Wechsel weitergeleitet. Der VectorFilter
    # kann bestimmte Wortklassen filtern und die Ergebnisse in verschiedenen Arten aufbereiten.
    # Dabei werden Funktionen wie das einfache Zählen der Häufigkeit innerhalb eines Dokuments,
    # aber auch die Term-Frequenz und unterschiedliche Ausgabeformate unterstützt.
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
    # <b><i>lexicals</i></b>:: (Standard: '[sy]' => die Wortklassen Substantiv und Synonyme werden gefiltert)
    #                          Es können in eckige Klammern beliebige Wortklassen angegeben werden (siehe lib/strings.rb).
    #                          Der Parameter wird als regulärer Ausdruck ausgewertet.
    # <b><i>sort</i></b>:: (Standard: 'normal')
    #                      Der Parameter +sort+ beeinflußt Verarbeitung und Ausgabeformat des VectorFilters.
    #                      normal:: Jedes gefilterte Wort wird einmalig (keine Doppelnennungen!) in
    #                               alphabetischer Reihenfolge in der Form "wort" ausgegeben.
    #                      term_abs:: Jedes gefilterte Wort wird einmalig in absteigender Häufigkeit mit Angabe
    #                                 der absoluten Häufigkeit im Dokument in der Form "12 wort" ausgegeben.
    #                      term_rel:: Jedes gefilterte Wort wird einmalig in absteigender Häufigkeit mit Angabe
    #                                 der relativen Häufigkeit im Dokument in der Form "0.1234 wort" ausgegeben.
    #                      sto_abs:: Jedes gefilterte Wort wird einmalig in absteigender Häufigkeit mit Angabe
    #                                der absoluten Häufigkeit im Dokument in der Form "wort {12}" ausgegeben.
    #                      sto_rel:: Jedes gefilterte Wort wird einmalig in absteigender Häufigkeit mit Angabe
    #                                der relativen Häufigkeit im Dokument in der Form "wort {0.1234}" ausgegeben.
    # <b><i>skip</i></b>:: (Standard: TA_PUNCTUATION und TA_OTHER) Hiermit wird angegeben, welche Objekte nicht
    #                      verarbeitet werden sollen. Die +skip+-Angabe bezieht sich auf das Attribut +attr+ von
    #                      Token oder Word-Objekten.
    #
    # === Beispiele
    # Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
    #   meeting:
    #     attendees:
    #       - text_reader:   { out: lines, files: '$(files)' }
    #       - tokenizer:     { in: lines, out: token }
    #       - word_searcher: { in: token, out: words, source: 'sys-dic' }
    #       - vector_filter: { in: words, out: filtr, sort: 'term_rel' }
    #       - debugger:      { in: filtr, prompt: 'out>' }
    # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
    #   out> *FILE('test.txt')
    #   out> "0.28571 indexierung"
    #   out> *EOF('test.txt')

    class VectorFilter < self

      DEFAULT_SRC_SEP = '|'

      protected

      def init
        if @debug = get_key('debug', false)
          @prompt = get_key('prompt', 'lex:) ')
          @preamble = get_key('preamble', true)
        else
          @lex  = get_re('lexicals', '[sy]')
          @skip = get_array('skip', DEFAULT_SKIP, :upcase)

          @dict = get_key('dict', false)
          @norm = get_key('norm', false) if @dict
          @dict = Database::Source::WordClass::DEFAULT_SEPARATOR if @dict == true

          @src = get_key('src', false)
          @src = DEFAULT_SRC_SEP if @src == true

          if sort = get_key('sort', ENV['LINGO_NO_SORT'] ? false : 'normal')
            @sort_format, @sort_method = sort.downcase.split('_', 2)
          end
        end

        @vectors, @word_count = [], 0
      end

      def control(cmd, *)
        case cmd
          when :EOL                 then skip_command
          when :FILE, :RECORD, :EOF then send_vectors unless @vectors.empty?
        end
      end

      def process(obj)
        if @debug
          forward((@preamble = nil; @lingo.config.to_h.to_yaml)) if @preamble
          forward("#{@prompt} #{obj.inspect}") if eval(@debug)
        elsif obj.is_a?(Word) && !@skip.include?(obj.attr)
          @word_count += 1

          if @dict
            vec, sep = [], Database::Source::WordClass::GENDER_SEPARATOR

            obj.get_class(@lex).each { |lex|
              str = "#{lex.form} ##{lex.attr}"
              str << sep << lex.gender if lex.gender
              vec << str
            }

            unless vec.empty?
              wrd = @norm ? obj.lexicals.first.form : obj.form
              vec = Unicode.downcase("#{wrd}#{@dict}#{vec.join(' ')}")
              @sort_format ? @vectors << vec : forward(vec)
            end
          else
            obj.get_class(@lex).each { |lex|
              vec = Unicode.downcase(lex.form)
              vec << @src << lex.src if @src && lex.src
              @sort_format ? @vectors << vec : forward(vec)
            }
          end
        end
      end

      private

      def send_vectors
        if @sort_format == 'normal'
          @vectors.uniq!
          flush(@vectors.sort!)
        else
          cnt, fmt = Hash.new(0), '%d'

          @vectors.each { |v| cnt[v] += 1 }.clear
          vec = cnt.sort_by { |v, c| [-c, v] }

          if @sort_method == 'rel'
            fmt, wc = '%6.5f', @word_count.to_f
            vec.each { |v| v[1] /= wc }
          end

          if @sort_format == 'sto'
            fmt, @word_count = "%s {#{fmt}}", 0
          else
            fmt.insert(1, '2$') << ' %1$s'
          end

          vec.each { |v| forward(fmt % v) }
        end
      end

    end

    # For backwards compatibility.
    Vectorfilter  = VectorFilter
    Vector_filter = VectorFilter

  end

end
