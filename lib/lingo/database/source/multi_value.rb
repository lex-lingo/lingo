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

      # Abgeleitet von Source behandelt die Klasse Dateien mit dem Format <tt>MultiValue</tt>.
      # Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ nil, ['triumph', 'sieg', 'erfolg'] ]</tt>.
      # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

      class MultiValue < self

        DEFAULT_SEPARATOR = ';'

        def initialize(id, lingo)
          super
          @pat = /^#{@wrd}(?:#{Regexp.escape(@sep ||= DEFAULT_SEPARATOR)}#{@wrd})*$/
        end

        def set(db, key, val)
          values = val.map { |v| @def ? "#{v}##{@def}" : v }
          val.each { |v| db[v] = values }
        end

        private

        def convert_line(line, key, val)
          [nil, line.split(@sep).each { |i| i.strip! }]
        end

      end

    end

  end

end
