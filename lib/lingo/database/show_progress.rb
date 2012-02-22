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

  class Database

    class ShowProgress

      def initialize(src, max, act = true)
        @out, @act = src.instance_variable_get(:@lingo).config.stderr, act

        # To get the length of the formatted string we have
        # to actually substitute the placeholder.
        fmt = ' [%3d%%]'
        len = (fmt % 0).length

        # Now we know how far to "go back" to
        # overwrite the formatted string...
        back = "\b" * len

        @fmt = fmt       + back
        @clr = ' ' * len + back

        print src.instance_variable_get(:@config)['name'], ': '

        @rat, @cnt, @next = max / 100.0, 0, 0
        print 'convert '
        step

        yield self

        print "#{@clr}ok\n"
      end

      def [](value)
        @cnt = value
        step if @cnt >= @next
      end

      private

      def step
        percent = @cnt / @rat
        @next = (percent + 1) * @rat

        print @fmt % percent if percent.finite?
      end

      def print(*args)
        @out.print(*args) if @act
      end

    end

  end

end
