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

require 'safe_yaml/load'
require_relative 'cli'

class Lingo

  class Config

    def initialize(*args)
      @deprecated = Hash.new { |h, k| h[k] = true; false }

      @cli, @opts = CLI.new, {}

      @cli.execute(*args)
      @cli.options.each { |key, val| @opts[key.to_s] = val }

      load_config('language', :lang)
      load_config('config')

      if Array(self['meeting/attendees']).flat_map(&:keys).include?('textreader')
        deprecate(:textreader, :text_reader)
      end

      if r = get('meeting/attendees', 'text_reader') ||
             get('meeting/attendees', 'textreader')  # DEPRECATE textreader
        f = @cli.files

        if i = r['files']
          r['files'] = i.strip == '$(files)' ? f : i.split(SEP_RE)
        elsif !f.empty?
          r['files'] = f
        end
      end
    end

    def to_h
      @opts
    end

    def [](key)
      key_to_nodes(key).inject(to_h) { |hash, node| hash[node] }
    end

    def []=(key, val)
      nodes = key_to_nodes(key); node = nodes.pop
      (self[nodes_to_key(nodes)] ||= {})[node] = val
    end

    def get(key, *names)
      val = self[key]

      while name = names.shift
        case val
          when Hash  then val = val[name]
          when Array then val = val.find { |h|
            k, v = h.dup.shift
            break v if k == name
          }
          else break
        end
      end

      val
    end

    def stdin
      @cli.stdin
    end

    def stdout
      @cli.stdout
    end

    def stderr
      @cli.stderr
    end

    def warn(*msg)
      stderr.puts(*msg)
    end

    def quit(*args)
      @cli.send(:quit, *args)
    end

    def deprecate(old, new, obj = self)
      unless @deprecated[[source = obj.class.name.sub(/\ALingo::/, ''), old]]
        warn(
          "DEPRECATION WARNING: #{source} option `#{old}' is deprecated " <<
          "and will be removed in Lingo 1.9. Please use `#{new}' instead."
        )
      end
    end

    private

    def key_to_nodes(key)
      key.downcase.split('/')
    end

    def nodes_to_key(nodes)
      nodes.join('/')
    end

    def load_config(key, type = key.to_sym)
      file = Lingo.find(type, @opts[key]) { quit }
      File.open(file, encoding: ENC) { |f| @opts.update(SafeYAML.load(f)) }
    rescue Psych::SyntaxError => err
      err.message << " (in #{file})"
      raise
    end

  end

end
