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

require 'cyclops'

class Lingo

  class CLI < Cyclops

    class << self

      def defaults
        super.merge(
          config:   'lingo.cfg',
          language: 'de',
          profile:  false
        )
      end

    end

    attr_reader :files

    def run(arguments)
      @files = arguments
    end

    private

    def load_config(*)
      @config = {}
    end

    def opts(opts)
      opts.option(:language__LANG, "Language for processing [Default: #{defaults[:language]}]")

      opts.separator

      opts.option(:log__FILE, :L, 'Log file to print debug information to') { |log|
        options[:log] = stderr.reopen(log == '-' ? stdout : File.open(log, 'a+', encoding: ENC))
      }

      opts.separator

      opts.option(:profile__PATH, :P, 'Print profiling results') { |profile|
        options[:profile] = stdout if profile == '-'
      }
    end

  end

end
