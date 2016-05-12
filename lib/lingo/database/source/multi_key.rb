# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2016 John Vorhauer, Jens Wille                           #
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

      #--
      # Abgeleitet von Source behandelt die Klasse Dateien mit dem Format <tt>MultiKey</tt>.
      # Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ 'triumph', ['sieg', 'erfolg'] ]</tt>.
      # Die Sonderbehandlung erfolgt in der Methode Database#convert, wo daraus Schlüssel-Werte-Paare in der Form
      # <tt>[ 'sieg', ['triumph'] ]</tt> und <tt>[ 'erfolg', ['triumph'] ]</tt> erzeugt werden.
      # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.
      #++

      class MultiKey < self

        DEFAULT_SEPARATOR = ';'.freeze

        def initialize(id, lingo)
          super
          @pat = /^#{@wrd}(?:#{Regexp.escape(@sep)}#{@wrd})*$/
        end

        def set(db, key, val)
          key = lexical(key, @def) if @def
          val.each { |v| db[v] = [key] }
        end

        private

        def convert_line(line, key, val)
          values = line.split(@sep).each { |i| i.strip! }
          [values.shift, values]
        end

      end

    end

  end

end
