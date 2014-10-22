# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2014 John Vorhauer, Jens Wille                           #
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

  class Call < self

    CHANNELS = %w[stdout stderr].freeze

    def initialize(args = [])
      super(args, StringIO.new, StringIO.new, StringIO.new)
    end

    def call
      invite

      if block_given?
        begin
          yield self
        ensure
          reset
        end
      else
        self
      end
    end

    def talk(input, raw = false)
      config.stdin.reopen(
        input.respond_to?(:read) ? input.read : input)

      start

      res = CHANNELS.flat_map { |key|
        io = config.send(key)
        io.rewind

        lines = io.readlines

        io.truncate(0)
        io.rewind

        lines
      }

      return res.join if raw

      res.each { |i| i.chomp! }

      block_given? ? res.map! { |i| yield i } : begin
        res.sort! unless ENV['LINGO_NO_SORT']
        res.uniq!
        res
      end
    end

  end

end
