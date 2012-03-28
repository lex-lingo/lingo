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

  class Attendee

    class Stemmer < self

      protected

      def init
        extend(Lingo.get_const(get_key('type', 'porter'), self.class))

        @wc  = get_key('wordclass', LA_STEM)
        @all = get_key('mode', '').downcase == 'all'
      end

      def process(obj)
        if obj.is_a?(Word) && obj.unknown?
          stem = stem(obj.form.downcase, @all)
          obj.add_lexicals([Lexical.new(stem, @wc)]) if stem
        end

        forward(obj)
      end

    end

  end

end

require_relative 'stemmer/porter'
