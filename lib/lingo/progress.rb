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

  class Progress

    def initialize(obj, max, name = nil, doit = true, text = 'progress', nl = true, &block)
      @doit, @out = doit, obj.lingo.config.stderr

      if max && doit
        format = ' [%3d%%]'
        length = (format % 0).length

        erase = "\b" * length
        @format = format + erase

        print name, ': ' if name
        print text

        init(max)

        msg = %w[done aborted]
      end

      suc = false

      res = catch(:cancel) {
        int = trap(:INT) { throw(:cancel) }

        begin
          yield self
        ensure
          trap(:INT, &int)
        end

        suc = true
        nil
      }

      print ' ' * length + erase, ' ', msg[suc ? 0 : 1], '.' if msg
      print "\n" if msg && res

      print Array(res).join("\n") if res
      print "\n" if nl && (msg || res)
    end

    def init(max, doit = @doit)
      if max && doit
        @ratio, @next = max / 100.0, 0
        self << @count = 0
      end
    end

    def <<(value)
      if defined?(@count) && (@count = value) >= @next
        percent = @count / @ratio
        @next = (percent + 1) * @ratio

        print @format % percent if percent.finite?
      end
    end

    private

    def print(*args)
      @out.print(*args)
    end

  end

end
