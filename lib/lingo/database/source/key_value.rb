# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2013 John Vorhauer, Jens Wille                           #
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

  class Database

    class Source

      # Abgeleitet von Source behandelt die Klasse Dateien mit dem Format <tt>KeyValue</tt>.
      # Eine Zeile <tt>"Fachbegriff*Fachterminus\n"</tt> wird gewandelt in <tt>[ 'fachbegriff', ['fachterminus#s'] ]</tt>.
      # Die Wortklasse kann über den Parameter <tt>def-wc</tt> beeinflusst werden.
      # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

      class KeyValue < self

        DEFAULT_SEPARATOR = '*'

        def initialize(id, lingo)
          super(id, lingo, Language::LA_UNKNOWN)
          @pat = /^(#{@wrd})#{Regexp.escape(@sep ||= DEFAULT_SEPARATOR)}(#{@wrd})$/
        end

        private

        def convert_line(line, key, val)
          [key.strip, %W[#{val.strip}##{@def}]]
        end

      end

    end

  end

end
