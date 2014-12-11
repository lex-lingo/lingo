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

  class DeferredAttendee < Attendee

    def self.enhance(base)
      base.instance_variable_set(:@deferr_buffer, [])

      def base.command(*args)
        @deferr_buffer << buf = [args]

        args.first != :EOT ? buf << control_deferred(*args) :
          flush_deferred { |block|
            @deferr_buffer.each { |command_args, control_args|
              super(*command_args)
              block[*control_args] if control_args
            }
          }
      end
    end

    def initialize(config, lingo)
      self.class.enhance(self)
      super
    end

    def control_deferred(cmd, *)
      raise NotImplementedError, 'must be implemented by subclass'
    end

    def flush_deferred(&block)
      raise NotImplementedError, 'must be implemented by subclass'
    end

  end

end
