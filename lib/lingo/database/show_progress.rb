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

      def initialize(msg, active = true, out = $stderr)
        @active, @out, format = active, out, ' [%3d%%]'

        # To get the length of the formatted string we have
        # to actually substitute the placeholder.
        length = (format % 0).length

        # Now we know how far to "go back" to
        # overwrite the formatted string...
        back = "\b" * length

        @format = format       + back
        @clear  = ' ' * length + back

        print msg, ': '
      end

      def start(msg, max)
        @ratio, @count, @next_step = max / 100.0, 0, 0
        print msg, ' '
        step
      end

      def stop(msg)
        print @clear
        print msg, "\n"
      end

      def tick(value)
        @count = value
        step if @count >= @next_step
      end

      private

      def step
        percent = @count / @ratio
        @next_step = (percent + 1) * @ratio

        print @format % percent
      end

      def print(*args)
        @out.print(*args) if @active
      end

    end

  end

end
