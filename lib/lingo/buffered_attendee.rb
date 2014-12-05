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

  class BufferedAttendee < Attendee

    def initialize(config, lingo)
      @buffer = []
      super
    end

    def process(obj)
      @buffer << obj
      process_buffer if process_buffer?
    end

    private

    def form_at(index, klass = WordForm)
      obj = @buffer[index]
      obj.form if obj.is_a?(klass)
    end

    def forward_number_of_token(len = default = @buffer.size, punct = !default)
      begin
        unless @buffer.empty?
          forward(item = @buffer.delete_at(0))
          len -= 1 unless punct && item.form == CHAR_PUNCT
        end
      end while len > 0
    end

    def valid_tokens_in_buffer
      @buffer.count { |item| item.form != CHAR_PUNCT }
    end

    def process_buffer?
      !instance_variable_defined?(:@expected_tokens_in_buffer) ||
      valid_tokens_in_buffer >= @expected_tokens_in_buffer
    end

    def process_buffer
      raise NotImplementedError
    end

    def control_multi(cmd)
      if [:RECORD, :EOF].include?(cmd)
        @eof_handling = true

        while valid_tokens_in_buffer > 1
          process_buffer
        end

        forward_number_of_token

        @eof_handling = false
      end
    end

  end

end
