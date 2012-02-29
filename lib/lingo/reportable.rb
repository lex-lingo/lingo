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
      @reportable_hash   = Hash.new(0)
      @reportable_prefix = prefix ? "#{prefix}: " : ''
    end

    def inc(key)
      @reportable_hash[key] += 1
    end

    def add(key, val)
      @reportable_hash[key] += val
    end

    def set(key, val)
      @reportable_hash[key] = val
    end

    def get(key)
      @reportable_hash[key]
    end

    def report
      q = @reportable_prefix
      @reportable_hash.each_with_object({}) { |(k, v), r| r["#{q}#{k}"] = v }
    end

  end

end
