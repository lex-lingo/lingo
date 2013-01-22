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

require 'json'
require 'strscan'
require 'nuggets/util/ruby'

require_relative 'app'

class Lingo

  class Web < App

    init_app(__FILE__)

    HL, L = %w[en de ru], Lingo.list(:lang).map! { |lang|
      lang[%r{.*/(\w+)\.}, 1]
    }.uniq.sort!

    auth, cfg = %w[auth cfg].map! { |ext|
      File.join(root, "lingoweb.#{ext}")
    }

    if File.readable?(auth)
      c = File.read(auth).chomp.split(':', 2)
      use(Rack::Auth::Basic) { |*b| b == c } unless c.empty?
    end

    LINGO = Hash.new { |h, k| h[k] = Lingo.call(cfg, ['-l', k]) }

    CFG, s = '', StringScanner.new('')
    c = lambda { |n| %Q{<span style="color:#{n}">#{s.matched}</span>} }

    File.foreach(cfg) { |line|
      s.string = line.chomp

      until s.eos?
        CFG << if s.scan(/\s+/)   then c[:black]
        elsif s.scan(/---|[{}:]/) then c[:purple]
        elsif s.scan(/-/)         then c[:olive]
        elsif s.scan(/,/)         then c[:black]
        elsif s.scan(/[\w-]+/)    then c[s.peek(1) == ':' ? :teal : :black]
        elsif s.scan(/'.*?'/)     then c[:maroon]
        elsif s.scan(/"/)
          buf = c[:maroon]

          until s.scan(/"/)
            buf << (s.scan(/\\\w/) ? c[:purple] : (s.scan(/./); c[:maroon]))
          end

          buf << c[:maroon]
        else s.rest
        end
      end

      CFG << "\n"
    }

    before do
      @hl = if v = params[:hl] || cookies[:hl] || env['HTTP_ACCEPT_LANGUAGE']
        v = v.split(',').map { |l| l.split('-').first.strip }
        (v & HL).first
      end || HL.first

      cookies[:hl] = @hl unless cookies[:hl] == @hl

      @q = params[:q]
      @l = params[:l] || @hl
      @l = L.first unless L.include?(@l)
    end

    get('')   { redirect url_for('/') }
    get('/')  { doit }
    post('/') { doit }

    helpers do
      def url_for(path)
        "#{request.script_name}#{path}"
      end

      def t(*t)
        (i = HL.index(@hl)) && t[i] || t.first
      end
    end

    def doit
      @r = LINGO[@l].talk(@q) { |_| _ } if @q && !@q.empty?

      case params[:f]
        when 'json'
          to_json(@q, @r)
        when 'text'
          @r &&  @r.join("\n")
        else
          @r &&= @r.join("\n")
          erb :index
      end
    end

  end

end
