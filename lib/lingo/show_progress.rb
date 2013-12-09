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

  class ShowProgress

    def initialize(obj, max, name = nil, doit = true, text = 'progress', nl = true, &block)
      @doit, @nl, @out = doit, nl, obj.instance_variable_get(:@lingo).config.stderr

      return handle(&block) unless max && doit

      # To get the length of the formatted string we have
      # to actually substitute the placeholder.
      fmt = ' [%3d%%]'
      len = (fmt % 0).length

      # Now we know how far to "go back" to
      # overwrite the formatted string...
      back = "\b" * len

      @fmt = fmt       + back
      @clr = ' ' * len + back

      print name, ': ' if name
      print text

      init(max)

      handle(%w[done aborted], &block)
    end

    def init(max, doit = @doit)
      return unless max && doit

      @rat, @cnt, @next = max / 100.0, 0, 0
      step
    end

    def [](value)
      if defined?(@cnt)
        @cnt = value
        step if @cnt >= @next
      end
    end

    private

    def step
      percent = @cnt / @rat
      @next = (percent + 1) * @rat

      print @fmt % percent if percent.finite?
    end

    def print(*args)
      @out.print(*args)
    end

    def handle(msg = nil)
      suc = false

      res = catch(:cancel) {
        trap(:INT) { throw(:cancel) }
        yield self
        suc = true
      }

      res = nil if suc

      print @clr, ' ', msg[suc ? 0 : 1], '.' if msg
      print "\n" if msg && res

      print Array(res).join("\n") if res
      print "\n" if @nl && (msg || res)
    end

  end

end
