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

  module Language

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

  end

end
