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

    #--
    # Die Klasse WordForm ist die Basisklasse für weitere Klassen, die im Rahmen der
    # Objektstruktur eines Wortes benötigt werden. Die Klasse stellt eine Zeichenkette bereit,
    # die mit einem Attribut versehen werden kann.
    #++

    class WordForm

      include Comparable

      def initialize(form, attr = WA_UNSET, src = nil)
        attr, @gender = attr
        @form, @attr, @src = form || '', attr || '', src
      end

      attr_accessor :form, :attr, :gender, :src, :token, :head

      def unknown?
        [WA_UNKNOWN, WA_UNKMULPART].include?(attr)
      end

      def identified?
        attr == WA_IDENTIFIED
      end

      def word_token?
        false
      end

      def <=>(other)
        other.nil? ? 1 : to_a <=> other.to_a
      end

      def to_a
        [form, attr, gender]
      end

      def to_s
        to_a.compact.join('/')
      end

      def inspect
        to_s
      end

      def hash
        to_a.hash
      end

      def eql?(other)
        self.class.equal?(other.class) && (self <=> other) == 0
      end

      alias_method :==, :eql?

    end

  end

end
