# encoding: utf-8

class Lingo

  module Language

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
            a = Language::LA_SORTORDER.index(attr)
            b = Language::LA_SORTORDER.index(other.attr)

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

  end

end
