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

  require_optional 'sdbm'

  class Database

    module SDBMStore

      Database.register(self, %w[dir pag], -1, false)

      private

      def uptodate?
        super(@stofile + EXT.last)
      end

      def _clear
        File.delete(*Dir["#{@stofile}{#{EXT.join(',')}}"])
      end

      def _open
        SDBM.open(@stofile)
      end

      def _set(key, val)
        if val.length > 950
          warn "Warning: Entry `#{key}' (#{@srcfile}) too long for SDBM. Truncating..."
          val = val[0, 950]
        end

        super
      end

    end

  end

end
