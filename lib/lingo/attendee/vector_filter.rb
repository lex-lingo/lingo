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
    #++

    class VectorFilter < self

      DEFAULT_SRC_SEPARATOR = '|'
      DEFAULT_POS_SEPARATOR = '@'

      DEFAULT_DICT_SEPARATOR = Database::Source::WordClass::DEFAULT_SEPARATOR

      DEFAULT_GENDER_SEPARATOR = Database::Source::WordClass::GENDER_SEPARATOR

      protected

      def init
        @lex  = get_re('lexicals', '[sy]')
        @skip = get_array('skip', DEFAULT_SKIP, :upcase)

        @src, @pos, @tokens, @sort_format, @sort_method =
          nil, nil, [], nil, nil

        if @dict = get_key('dict', false)
          @norm = get_key('norm', false)
          @dict = DEFAULT_DICT_SEPARATOR if @dict == true
        else
          @src = get_key('src', false)
          @src = DEFAULT_SRC_SEPARATOR if @src == true

          @pos = get_key('pos', false)
          @pos = DEFAULT_POS_SEPARATOR if @pos == true

          @tokens = get_array('tokens', '', :upcase)
          @tokens.concat(Tokenizer.rules) if @tokens.delete('ALL')
        end

        if sort = get_key('sort', ENV['LINGO_NO_SORT'] ? false : 'normal')
          @sort_format, @sort_method = sort.downcase.split('_', 2)
        end

        @vectors, @word_count = Hash.new { |h, k| h[k] = [] }, 0
      end

      def control(cmd, *)
        case cmd
          when :EOL
            :skip_command
          when :FILE, :RECORD, :EOF
            send_vectors unless @vectors.empty?
            @word_count = 0
        end
      end

      def process(obj)
        if obj.is_a?(Token)
          return unless @tokens.include?(obj.attr)
        elsif obj.is_a?(Word)
          return if @skip.include?(obj.attr)
        else
          return
        end

        @word_count += 1

        @dict ? forward_dict(obj) : begin
          pos = obj.position_and_offset if @pos

          obj.is_a?(Token) ? forward_vector(obj, pos) :
            obj.get_class(@lex).each { |lex| forward_vector(lex, pos, lex.src) }
        end
      end

      private

      def forward_dict(obj, sep = DEFAULT_GENDER_SEPARATOR)
        vectors = obj.get_class(@lex).map { |lex|
          "#{lex.form} ##{lex.attr}".tap { |str|
            str << sep << lex.gender if lex.gender
          }
        }

        unless vectors.empty?
          vec = @norm ? obj.lexicals.first.form : obj.form
          forward_vector("#{vec}#{@dict}#{vectors.join(' ')}")
        end
      end

      def forward_vector(vec, pos = nil, src = nil)
        vec = vec.form if vec.is_a?(WordForm)

        vec = Unicode.downcase(vec)
        vec << @src << src if @src && src

        @sort_format ? @vectors[vec] << pos : forward(vec_pos(vec, [pos]))
      end

      def send_vectors
        if @sort_format == 'normal'
          vectors = !@pos ? @vectors.keys : @vectors.map { |i| vec_pos(*i) }

          @vectors.clear

          flush(vectors.sort!)
        else
          vectors = @vectors.sort_by { |vec, pos| [-pos.size, vec] }

          @vectors.clear

          !@pos ? vectors.map! { |vec, pos| [pos.size, vec] } :
            vectors.map! { |vec, pos| [pos.size, vec_pos(vec, pos)] }

          @sort_method != 'rel' ? fmt = '%d' : begin
            fmt, wc = '%6.5f', @word_count.to_f
            vectors.each { |v| v[0] /= wc }
          end

          @sort_format != 'sto' ? fmt << ' %s' :
            fmt = "%2$s {#{fmt.insert(1, '1$')}}"

          vectors.each { |vec| forward(fmt % vec) }
        end
      end

      def vec_pos(vec, pos)
        pos.compact!
        pos.uniq!
        pos.empty? ? vec : "#{vec}#{@pos}#{pos.join(',')}"
      end

    end

    # For backwards compatibility.
    Vectorfilter  = VectorFilter
    Vector_filter = VectorFilter

  end

end
