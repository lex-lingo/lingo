# encoding: utf-8

#--
# LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
# Mehrworterkennung und Relationierung.
#
# Copyright (C) 2005-2007 John Vorhauer
# Copyright (C) 2007-2011 John Vorhauer, Jens Wille
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
# For more information visit http://www.lex-lingo.de or contact me at
# welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
# Lex Lingo rules from here on
#++

class Lingo

  # Die Klasse WordForm ist die Basisklasse für weitere Klassen, die im Rahmen der
  # Objektstruktur eines Wortes benötigt werden. Die Klasse stellt eine Zeichenkette bereit,
  # die mit einem Attribut versehen werden kann.

  class WordForm

    include Comparable

    attr_accessor :form, :attr

    def initialize(form, attr = '-')
      @form, @attr = form || '', attr || ''
    end

    def <=>(other)
      other.nil? ? 1 : to_a <=> other.to_a
    end

    def to_a
      [form, attr]
    end

    def to_s
      to_a.join('/')
    end

    def inspect
      to_s
    end

    def hash
      to_s.hash
    end

    def eql?(other)
      self.class.equal?(other.class) && to_s == other.to_s
    end

    alias_method :==, :eql?

  end

  # Die Klasse Token, abgeleitet von der Klasse WordForm, stellt den Container
  # für ein einzelnes Wort eines Textes dar. Das Wort wird mit einem Attribut versehen,
  # welches der Regel entspricht, die dieses Wort identifiziert hat.
  #
  # Steht z.B. in ruby.cfg eine Regel zur Erkennung einer Zahl, die mit NUM bezeichnet wird,
  # so wird dies dem Token angeheftet, z.B. Token.new('100', 'NUM') -> #100/NUM#

  class Token < WordForm

    def to_s
      ":#{super}:"
    end

  end

  # Die Klasse Lexical, abgeleitet von der Klasse WordForm, stellt den Container
  # für eine Grundform eines Wortes bereit, welches mit der Wortklasse versehen ist.
  #
  # Wird z.B. aus dem Wörterbuch eine Grundform gelesen, so wird dies in Form eines
  # Lexical-Objektes zurückgegeben, z.B. Lexical.new('Rennen', 'S') -> (rennen/s)

  class Lexical < WordForm

    def <=>(other)
      return 1 unless other.is_a?(self.class)

      if attr == other.attr
        form <=> other.form
      else
        attr.empty? ? 1 : other.attr.empty? ? -1 : begin
          a = Attendee::LA_SORTORDER.index(attr)
          b = Attendee::LA_SORTORDER.index(other.attr)

          a ? b ? b <=> a : -1 : b ? 1 : attr <=> other.attr
        end
      end
    end

    def to_str
      to_a.join('#')
    end

    def to_s
      "(#{super})"
    end

  end

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

    def initialize(form, attr = Attendee::WA_UNSET)
      super
      @lexicals = []
    end

    def lexicals(compound_parts = true)
      if !compound_parts && attr == Attendee::WA_KOMPOSITUM
        @lexicals.select { |lex| lex.attr == Attendee::LA_KOMPOSITUM }
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

    # für Compositum
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
      attr == Attendee::WA_IDENTIFIED ? lexicals.first.form : form
    end

    def compo_form
      if attr == Attendee::WA_KOMPOSITUM
        get_class(Attendee::LA_KOMPOSITUM).first
      else
        nil
      end
    end

    def unknown?
      [Attendee::WA_UNKNOWN, Attendee::WA_UNKMULPART].include?(attr)
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
      s << "|#{attr}" unless attr == Attendee::WA_IDENTIFIED
      s << " = #{lexicals.inspect}" unless lexicals.empty?
      s << '>'
    end

  end

end
