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

require 'csv'

class Lingo

  class Attendee

    class AnalysisFilter < self

      FIELDS = {
        string:   :form,
        token:    :attr,
        position: :position,
        offset:   :offset,
        word:     :attr,
        pattern:  :pattern
      }

      def init
        @csv, @header = CSV.new('', row_sep: ''), FIELDS.keys
      end

      def control(cmd, *)
        :skip_command if cmd == :EOL
      end

      def process(obj, *)
        forward_row(@header.tap { @header = nil }) if @header

        obj.is_a?(Token) ?
          forward_obj(obj, obj, obj, obj) : begin
        tok = obj.token
          forward_obj(obj, nil, tok, tok, obj, obj)
        obj.lexicals.each { |lex|
          forward_obj(lex, nil, tok, tok, lex, obj) }
        end
      end

      private

      def forward_obj(*args)
        forward_row(FIELDS.map.with_index { |(_, method), index|
          arg = args[index] and arg.send(method) })
      end

      def forward_row(row)
        forward(@csv.add_row(row).string.dup)
        @csv.string.clear
        @csv.rewind
      end

    end

  end

end
