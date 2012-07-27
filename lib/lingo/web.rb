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
require 'nuggets/util/ruby'

require_relative 'app'

class Lingo

  class Web < App

    init_app(__FILE__)

    UILANGS, LANGS = %w[en de], Lingo.list(:lang).map! { |lang|
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

    before do
      @uilang = if hal = env['HTTP_ACCEPT_LANGUAGE']
        hals = hal.split(',').map { |l| l.split('-').first.strip }
        (hals & UILANGS).first
      end || UILANGS.first

      @q = params[:q]
      @l = params[:l] || @uilang
      @l = LANGS.first unless LANGS.include?(@l)
    end

    get('')   { redirect url_for('/') }
    get('/')  { doit }
    post('/') { doit }

    helpers do
      def url_for(path)
        "#{request.script_name}#{path}"
      end

      def t(*t)
        (i = UILANGS.index(@uilang)) && t[i] || t.first
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
