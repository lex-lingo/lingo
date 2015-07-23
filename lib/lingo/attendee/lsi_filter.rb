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

    class LsiFilter < DeferredAttendee

      def init
        require_lib('lsi4r')

        @lex  = get_re('lexicals', '[sy]')
        @skip = get_ary('skip', DEFAULT_SKIP, :upcase)

        @transform = get_key('transform', Lsi4R::DEFAULT_TRANSFORM)
        @cutoff    = get_flo('cut',       Lsi4R::DEFAULT_CUTOFF)

        @min = get_flo('min', false)
        @abs = get_flo('abs', false)
        @nul = get_flo('nul', false)
        @new = get_key('new', true)

        @sort = get_key('sort', false)
        @sort.downcase! if @sort.respond_to?(:downcase!)

        @docnum, @vectors = 0, Hash.new { |h, k| h[k] = [] }
      end

      def control(cmd, *)
        :skip_command if cmd == :EOL
      end

      def control_deferred(cmd, *)
        @docnum += 1 if TERMINALS.include?(cmd)
      end

      def process(obj)
        if obj.is_a?(Word) && !@skip.include?(obj.attr)
          vec = []
          obj.each_lex(@lex) { |lex| vec << Unicode.downcase(lex.form) }
          @vectors[@docnum].concat(vec) unless vec.empty?
        end
      end

      private

      def send_lsi
        lsi = Lsi4R.new(@vectors); @vectors.clear

        if lsi.build(transform: @transform, cutoff: @cutoff)
          options, vec = { min: @min, abs: @abs, nul: @nul, new: @new }, []

          fmt = @sort ? @sort == 'sto' ?
            '%s {%.5f}' : '%2$.5f %1$s' : '%s %.5f' unless @sort == 'normal'

          yield !@sort ? lambda { |docnum|
            lsi.each_norm(docnum, options) { |_, *v| forward(fmt % v) }
          } : lambda { |docnum|
            lsi.each_norm(docnum, options) { |_, *v| vec << v }

            !fmt ? vec.sort!.each { |v, _| forward(v) } :
              vec.sort_by { |v, w| [-w, v] }.each { |v| forward(fmt % v) }

            vec.clear
          }
        end
      end

      alias_method :flush_deferred, :send_lsi

    end

  end

end
