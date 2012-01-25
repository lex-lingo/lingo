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

  # Provides counters.

  module Reportable

    def init_reportable(prefix = nil)
      @counters, @prefix = Hash.new(0), prefix ? "#{prefix}: " : ''
    end

    def inc(counter)
      @counters[counter] += 1
    end

    def add(counter, value)
      @counters[counter] += value
    end

    def set(counter, value)
      @counters[counter] = value
    end

    def get(counter)
      @counters[counter]
    end

    def report
      @counters.each_with_object({}) { |(k, v), r| r["#{@prefix}#{k}"] = v }
    end

  end

end
