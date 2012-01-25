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

      def self.new_lexical(form, attr, lex_attr)
        new(form, attr) << Lexical.new(form, lex_attr)
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

      def initialize(form, attr = Language::WA_UNSET)
        super
        @lexicals = []
      end

      def lexicals(compound_parts = true)
        if !compound_parts && attr == Language::WA_KOMPOSITUM
          @lexicals.select { |lex| lex.attr == Language::LA_KOMPOSITUM }
        else
          @lexicals
        end
      end

      def lexicals=(lexis)
        if lexis.is_a?(Array)
          @lexicals = lexis.sort.uniq
        else
          raise 'Falscher Typ bei Zuweisung'
        end
      end

      def attrs(compound_parts = true)
        lexicals(compound_parts).map { |lex| lex.attr }
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
        attr == Language::WA_IDENTIFIED ? lexicals.first.form : form
      end

      def compo_form
        if attr == Language::WA_KOMPOSITUM
          get_class(Language::LA_KOMPOSITUM).first
        else
          nil
        end
      end

      def unknown?
        [Language::WA_UNKNOWN, Language::WA_UNKMULPART].include?(attr)
      end

      def <<(*other)
        lexicals.concat(other.flatten)
        self
      end

      def <=>(other)
        other.nil? ? 1 : to_a.push(lexicals) <=> other.to_a.push(other.lexicals)
      end

      def to_s
        s =  "<#{form}"
        s << "|#{attr}" unless attr == Language::WA_IDENTIFIED
        s << " = #{lexicals.inspect}" unless lexicals.empty?
        s << '>'
      end

    end

  end

end
