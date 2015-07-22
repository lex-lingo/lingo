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

class Lingo

  class Attendee

    class HalFilter < self

      def init
        require_lib('hal4r')

        @lex  = get_re('lexicals', '[sy]')
        @skip = get_ary('skip', DEFAULT_SKIP, :upcase)

        @norm = get_key('norm', true)
        @sep  = get_key('sep', '^')
        @min  = get_flo('min', false)
        @dim  = get_int('dim', 2)

        @sort = get_key('sort', false)
        @sort.downcase! if @sort.respond_to?(:downcase!)

        @hal = Hal4R.new([], get_int('window-size', Hal4R::DEFAULT_WINDOW_SIZE))
      end

      def control(cmd, *)
        case cmd
          when :EOL       then :skip_command
          when *TERMINALS then send_vectors unless @hal.empty?
        end
      end

      def process(obj)
        obj.is_a?(Word) && !@skip.include?(obj.attr) &&
          # TODO: which lexical to select? (currently: first)
          obj.lex_form(@lex) { |form| @hal << Unicode.downcase(form) }
      end

      private

      def send_vectors
        vec = []

        fmt = @sort ? @sort == 'sto' ?
          '%s {%.5f}' : '%2$.5f %1$s' : '%s %.5f' unless @sort == 'normal'

        unless @sort
          each_vector { |v| forward(fmt % v) }
        else
          each_vector { |v| vec << v }

          !fmt ? vec.sort!.each { |v, _| forward(v) } :
            vec.sort_by { |v, w| [-w, v] }.each { |v| forward(fmt % v) }

          vec.clear
        end

        @hal.reset
      end

      def each_vector
        @hal.each_distance(@norm, @dim) { |*t, v| v = 1 / v
          yield [t.join(@sep), v] unless v.nan? || (@min && v < @min) }
      end

    end

  end

end
