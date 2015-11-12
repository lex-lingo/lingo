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

class Lingo

  module Language

    #--
    # Die Klasse Word bündelt spezifische Eigenschaften eines Wortes mit den
    # dazu notwendigen Methoden.
    #++

    class Word < WordForm

      class << self

        def new_lexicals(form, attr, lex)
          new(form, attr) << lex
        end

        def new_lexical(form, attr, lex_attr)
          new_lexicals(form, attr, Lexical.new(form, lex_attr))
        end

        def new_compound_head(lex, attr = WA_UNSET)
          form, head_lex = nil, []

          lex.reverse_each { |l|
            src =  l.src ||= l.form
            form ||= src
            form  != src ? break : head_lex.unshift(l.dup)
          }

          head_lex.each { |l| l.attr = l.attr[/\w+/] }.uniq!

          new_lexicals(form, attr, head_lex) if form
        end

      end

      #--
      # Exakte Representation der originären Zeichenkette, so wie sie im Satz
      # gefunden wurde, z.B. <tt>form = "RubyLing"</tt>
      #
      # Ergebnis der Wörterbuch-Suche. Sie stellt die Grundform des Wortes dar.
      # Dabei kann es mehrere mögliche Grundformen geben, z.B. kann +abgeschoben+
      # als Grundform das _Adjektiv_ +abgeschoben+ sein, oder aber das _Verb_
      # +abschieben+.
      #
      # <tt>lemma = [['abgeschoben', '#a'], ['abschieben', '#v']]</tt>.
      #
      # <b>Achtung: Lemma wird nicht durch die Word-Klasse bestückt, sondern extern
      # durch die Klasse Dictionary</b>
      #++

      def initialize(form, attr = WA_UNSET, token = nil)
        @token, @lexicals = token, []
        super
      end

      attr_accessor :lexicals, :pattern

      def add_lexicals(lex)
        lexicals.concat(lex - lexicals)
      end

      def attr?(*attr)
        !(attrs & attr).empty?
      end

      def attrs
        lexicals.map(&:attr)
      end

      def compound_attrs
        attr == WA_COMPOUND ? attrs.grep(LA_COMPOUND) : attrs
      end

      def genders
        lexicals.map(&:gender)
      end

      def identify(lex, wc = nil, seq = nil)
        return self if lex.empty?

        self.lexicals, self.pattern = lex, seq
        self.attr = wc ||= attr?(LA_COMPOUND) ? WA_COMPOUND : WA_IDENTIFIED
        self.head = self.class.new_compound_head(lex) if wc == WA_COMPOUND

        self
      end

      def each_lex(wc_re = //)
        return enum_for(__method__, wc_re) unless block_given?

        wc_re = Regexp.new(wc_re) unless wc_re.is_a?(Regexp)

        lexicals.empty? ? attr =~ wc_re ? yield(self) : nil :
          lexicals.each { |lex| yield lex if lex.attr =~ wc_re }

        nil
      end

      def lex_form(wc_re = //)
        each_lex(wc_re) { |lex|
          break block_given? ? yield(lex.form) : lex.form }
      end

      def position_and_offset
        token.position_and_offset if token
      end

      def <<(*lex)
        lex.flatten!
        lexicals.concat(lex)
        self
      end

      def <=>(other)
        other.nil? ? 1 : to_a.push(lexicals) <=> other.to_a.push(other.lexicals)
      end

      def to_s
        s =  "<#{form}"
        s << "|#{attr}" unless identified?
        s << " = #{lexicals.inspect}" unless lexicals.empty?
        s << '>'
      end

    end

  end

end
