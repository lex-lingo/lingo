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

  module Language

    # Die Klasse Word bündelt spezifische Eigenschaften eines Wortes mit den
    # dazu notwendigen Methoden.

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
            src =  l.src
            form ||= src
            form  != src ? break : head_lex.unshift(l.dup)
          }

          new_lexicals(form, attr, head_lex)
        end

      end

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

      def initialize(form, attr = WA_UNSET)
        super
        @lexicals = []
      end

      def lexicals(compound_parts = true)
        if !compound_parts && attr == WA_COMPOUND
          @lexicals.select { |lex| lex.attr == LA_COMPOUND }
        else
          @lexicals
        end
      end

      def lexicals=(lex)
        @lexicals = lex.uniq
      end

      def add_lexicals(lex)
        @lexicals.concat(lex).uniq! unless lex.empty?
      end

      def attr?(*attr)
        !(attrs & attr).empty?
      end

      def attrs(compound_parts = true)
        lexicals(compound_parts).map { |i| i.attr }
      end

      def genders(compound_parts = true)
        lexicals(compound_parts).map { |i| i.gender }
      end

      def parts
        1
      end

      def min_part_size
        form.length
      end

      # Gibt genau die Grundform der Wortklasse zurück, die der RegExp des Übergabe-Parameters
      # entspricht, z.B. <tt>word.get_wc(/a/) = ['abgeschoben', '#a']</tt>
      def get_class(wc_re)
        wc_re = Regexp.new(wc_re) unless wc_re.is_a?(Regexp)

        unless lexicals.empty?
          lexicals.select { |lex| lex.attr =~ wc_re }
        else
          attr =~ wc_re ? [self] : []
        end
      end

      def norm
        identified? ? lexicals.first.form : form
      end

      def compo_form
        get_class(LA_COMPOUND).first if attr == WA_COMPOUND
      end

      def full_compound?
        attr == WA_COMPOUND && get_class('x+').empty?
      end

      def multiword_size(wc_re = LA_MULTIWORD)
        lex = get_class(wc_re).first and lex.form.count(' ') + 1
      end

      def <<(*lex)
        lex.flatten!
        @lexicals.concat(lex)
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
