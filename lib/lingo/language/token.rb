# encoding: utf-8

class Lingo

  module Language

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

  end

end
