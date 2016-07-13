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

      include TextUtils

      DEFAULT_SRC_SEPARATOR = '|'
      DEFAULT_POS_SEPARATOR = '@'

      DEFAULT_DICT_SEPARATOR = Database::Source::WordClass::DEFAULT_SEPARATOR

      DEFAULT_GENDER_SEPARATOR = Database::Source::WordClass::GENDER_SEPARATOR

      def init
        @lex  = get_re('lexicals', '[sy]')
        @skip = get_ary('skip', DEFAULT_SKIP, :upcase)

        @src = @pos = @sort_fmt = @sort_rel = @docnum = nil

        @tokens, @vectors, @word_count = [], Hash.array(1), Hash.new(0)

        if @dict = get_key('dict', false)
          @norm = get_key('norm', false)
          @dict = DEFAULT_DICT_SEPARATOR if @dict == true
        else
          @src = get_key('src', false)
          @src = DEFAULT_SRC_SEPARATOR if @src == true

          @pos = get_key('pos', false)
          @pos = DEFAULT_POS_SEPARATOR if @pos == true

          @tokens = get_ary('tokens', '', :upcase)
          @tokens.concat(Tokenizer.rules) if @tokens.delete('ALL')
        end

        if sort = get_key('sort', ENV['LINGO_NO_SORT'] ? false : 'normal')
          @sort_fmt, sort_method = sort.downcase.split('_', 2)

          @sort_rel = rel = sort_method == 'rel'

          unless @sort_fmt == 'normal'
            if @tfidf = get_key('tfidf', false)
              DeferredAttendee.enhance(self)
              @docnum, rel = 0, true
            end

            _sort_fmt = @sort_fmt == 'sto' ? '%2$s {%1$X}' : '%X %s'
            @sort_fmt = _sort_fmt.sub('X', rel ? '.5f' : 'd')
          end
        end
      end

      def control(cmd, *)
        case cmd
          when :EOL       then :skip_command
          when *TERMINALS then send_vectors unless @docnum
        end
      end

      def control_deferred(cmd, *)
        @docnum += 1 if TERMINALS.include?(cmd)
      end

      def process(obj)
        if obj.is_a?(Token)
          return unless @tokens.include?(obj.attr)
        elsif obj.is_a?(Word)
          return if @skip.include?(obj.attr)
        else
          return
        end

        @word_count[@docnum] += 1

        @dict ? forward_dict(obj) : begin
          pos = obj.position_and_offset if @pos

          obj.is_a?(Token) ? forward_vector(obj, pos) :
            obj.each_lex(@lex) { |lex| forward_vector(lex, pos, lex.src) }
        end
      end

      private

      def vectors(docnum = nil)
        @vectors[docnum || @docnum]
      end

      def word_count(docnum = nil)
        @word_count[docnum || @docnum]
      end

      def forward_dict(obj, sep = DEFAULT_GENDER_SEPARATOR)
        vectors = obj.each_lex(@lex).map { |lex|
          "#{lex.form} ##{lex.attr}".tap { |str|
            str << sep << lex.gender if lex.gender
          }
        }

        unless vectors.empty?
          vec = @norm ? obj.lex_form : obj.form
          forward_vector("#{vec}#{@dict}#{vectors.join(' ')}")
        end
      end

      def forward_vector(vec, pos = nil, src = nil)
        vec = vec.form if vec.is_a?(WordForm)

        vec = Unicode.downcase(vec)
        vec << @src << src.form if @src && src

        @sort_fmt ? vectors[vec] << pos : forward(vec_pos(vec, [pos]))
      end

      def send_vectors
        if @docnum
          df, abs = Hash.new(0), @sort_rel ? nil : 1

          @vectors.each_value { |w| w.each_key { |v| df[v] += 1 } }

          if @tfidf.is_a?(String)
            open_csv(@tfidf, 'wb') { |c| df.sort.each { |v| c << v } }
          end

          yield lambda { |docnum|
            wc = abs || word_count(docnum)
            flush_vectors(wc, docnum) { |c, v, vp| [c / df[v], vp] }
          }
        elsif @sort_fmt == 'normal'
          flush(map_vectors { |_, _, vp| vp }.sort!)
        else
          flush_vectors(@sort_rel ? word_count : 1) { |c, _, vp| [c, vp] }
        end

        @word_count.clear
        @vectors.clear
      end

      alias_method :flush_deferred, :send_vectors

      def map_vectors(wc = 1, docnum = nil)
        v = vectors(docnum)
        v.map { |vec, pos| yield pos.size / wc.to_f, vec, vec_pos(vec, pos) }
      ensure
        v.clear if v
      end

      def flush_vectors(*args, &block)
        map_vectors(*args, &block)
          .sort_by { |w, v| [-w, v] }
          .each { |vec| forward(@sort_fmt % vec) }
      end

      def vec_pos(vec, pos)
        pos.clear unless @pos

        pos.compact!
        pos.uniq!
        pos.empty? ? vec : "#{vec}#{@pos}#{pos.join(',')}"
      end

    end

  end

end
