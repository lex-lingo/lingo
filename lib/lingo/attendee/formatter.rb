# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2015 John Vorhauer, Jens Wille                           #
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

  class Attendee

    class Formatter < TextWriter

      def init
        super

        @ext    = get_key('ext', '-')
        @format = get_key('format', '%s')
        @map    = get_key('map', Hash.identity)

        @no_puts = true
      end

      def process(obj)
        if obj.is_a?(WordForm)
          str = obj.form

          if obj.is_a?(Word)
            # TODO: which lexical to select? (currently: first)
            obj.each_lex { |lex|
              att = @map[lex.attr] and str = @format % [str, lex.form, att] }
          end
        else
          str = obj.to_s
        end

        @lir ? @lir_rec_buf << str : @file.print(str)
      end

    end

  end

end
