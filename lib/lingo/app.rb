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

require 'json'
require 'optparse'
require 'shellwords'
require 'sinatra/bells'

class Lingo

  class App < Sinatra::Bells

    class << self

      def init_app(file, *args, &block)
        set_root(file)
        parse_options(*args, &block)

        get('/about') { to_json(self.class, version: VERSION) }
      end

      def parse_options(lingo_options = false)
        argv, banner = [], "Usage: #{$0} [-h|--help] [sinatra-options]"
        while arg = ARGV.shift and arg != '--'; argv << arg; end

        if lingo_options || block_given?
          banner << ' [-- lingo-options]'

          opts = ENV["LINGO_#{name.split('::').last.upcase}_OPTS"]
          ARGV.unshift(*Shellwords.shellsplit(opts)) if opts

          ARGV.unshift(*lingo_options) if lingo_options.is_a?(Array)
        end

        OptionParser.new(banner, 12) { |o|
          o.on('-p port',   'set the port (default is 4567)')                { |v| set :port, Integer(v) }
          o.on('-o addr',   'set the host (default is 0.0.0.0)')             { |v| set :bind, v }
          o.on('-e env',    'set the environment (default is development)')  { |v| set :environment, v.to_sym }
          o.on('-s server', 'specify rack server/handler (default is thin)') { |v| set :server, v }
          o.on('-x',        'turn on the mutex lock (default is off)')       {     set :lock, true }
        }.parse!(argv)

        argv.pop if File.basename($0) == 'rackup'  # rackup config

        abort "Unrecognized arguments: #{argv}\n#{banner}" unless argv.empty?

        ARGV.unshift(*yield) if block_given?
      rescue OptionParser::ParseError => err
        abort "#{err}\n#{banner}"
      end

      def rackup(name)
        file = File.join(File.dirname(__FILE__), name, 'config.ru')
        file if File.readable?(file)
      end

    end

    def to_json(q, r)
      q, r = 'q', 'Required parameter -- Input string' unless q

      content_type :json
      { q => r }.to_json
    end

  end

end
