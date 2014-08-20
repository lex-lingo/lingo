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

require_relative 'app'

class Lingo

  class Srv < App

    init_app(__FILE__) { %W[-c #{File.join(root, 'lingosrv.cfg')}] }

    LINGO = Call.new(ARGV).call
    abort 'Something went wrong...' unless LINGO.is_a?(Call)

    c = LINGO.config.get('meeting/attendees', 'vector_filter', 'src')
    SRC_SEP = c == true ? Attendee::VectorFilter::DEFAULT_SRC_SEP : c

    get('')   { doit }
    get('/')  { doit }
    post('/') { doit }

    def doit
      to_json(q = params[:q], case q
        when String then talk(q)
        when Array  then q.inject({}) { |h, k| h[k] = talk(k); h }
      end)
    end

    def talk(q)
      r = LINGO.talk(q) unless q.empty?
      return r unless r && SRC_SEP

      s = Hash.new { |h, k| h[k] = [] }

      r.each { |t|
        a, b = t.split(SRC_SEP, 2)
        s[b] << a
      }

      ENV['LINGO_NO_SORT'] ? s.to_a : s
    end

  end

end
