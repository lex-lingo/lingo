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
      # Abgeleitet von Source behandelt die Klasse Dateien mit dem Format <tt>WordClass</tt>.
      # Eine Zeile <tt>"essen,essen #v essen #o esse #s\n"</tt> wird gewandelt in <tt>[ 'essen', ['esse#s', 'essen#v', 'essen#o'] ]</tt>.
      # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.
      #++

      class WordClass < self

        include ArrayUtils

        DEFAULT_SEPARATOR = ','.freeze

        GENDER_SEPARATOR  = '.'.freeze

        def initialize(id, lingo)
          super

          gen = Regexp.escape(GENDER_SEPARATOR)
          sep = Regexp.escape(@sep ||= DEFAULT_SEPARATOR)

          w, a = '\w%1$s(?:\|\w%1$s)*', '[+]?'
          wc   = "##{w % a}(?:#{gen}#{w % ''})?"

          @pat = /^(#{@wrd})#{sep}((?:#{@wrd}#{wc})+)$/
        end

        private

        def convert_line(line, key, val)
          values = []

          val.strip.scan(/(\S.*?)\s*#(\S+)/) { |k, v|
            v, f = v.split('.')

            combinations(v.split('|'), f ? f.split('|') : [nil]) { |w, g|
              values << "#{k}##{w}##{g}"
            }
          }

          [key.strip, values]
        end

      end

    end

  end

end
