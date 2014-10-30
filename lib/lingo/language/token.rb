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

  module Language

    # Die Klasse Token, abgeleitet von der Klasse WordForm, stellt den Container
    # für ein einzelnes Wort eines Textes dar. Das Wort wird mit einem Attribut versehen,
    # welches der Regel entspricht, die dieses Wort identifiziert hat.
    #
    # Steht z.B. in ruby.cfg eine Regel zur Erkennung einer Zahl, die mit NUM bezeichnet wird,
    # so wird dies dem Token angeheftet, z.B. Token.new('100', 'NUM') -> #100/NUM#

    class Token < WordForm

      POSITION_SEP = ':'

      def self.clean(attr)
        attr.sub(/:.*/, '')
      end

      def initialize(form, attr, position = nil, offset = nil)
        @position, @offset = position, offset
        super(form, self.class.clean(attr))
      end

      attr_reader :position, :offset

      def word?
        attr == TA_WORD
      end

      def position_and_offset
        "#{position}#{POSITION_SEP}#{offset}"
      end

      def to_a
        [form, attr, position, offset]
      end

      def to_s
        ":#{super}:"
      end

    end

  end

end
