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

    # Die Klasse Lexical, abgeleitet von der Klasse WordForm, stellt den Container
    # für eine Grundform eines Wortes bereit, welches mit der Wortklasse versehen ist.
    #
    # Wird z.B. aus dem Wörterbuch eine Grundform gelesen, so wird dies in Form eines
    # Lexical-Objektes zurückgegeben, z.B. Lexical.new('Rennen', 'S') -> (rennen/s)

    class Lexical < WordForm

      def attr?(attr)
        self.attr.start_with?(attr)
      end

      def <=>(other)
        return 1 unless other.is_a?(self.class)

        a1, a2 = attr, other.attr
        return form <=> other.form if a1 == a2

        a1.empty? ? 1 : a2.empty? ? -1 : begin
          i1, i2 = LA_SORTORDER.values_at(a1, a2)
          i1 ? i2 ? i1 <=> i2 : -1 : i2 ? 1 : a1 <=> a2
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
