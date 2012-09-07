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

require 'optparse'

class Lingo

  module Ctl

    extend self

    PROG, VERSION, OPTWIDTH = $0, '0.0.2', 18
    PROGNAME, OPTIONS = File.basename(PROG), {}

    COMMANDS, ALIASES = {}, Hash.new { |h, k|
      h[k] = COMMANDS.has_key?(k) ? k : 'usage'
    }

    USAGE = <<-EOT
Usage: #{PROG} <command> [arguments] [options]
       #{PROG} [-h|--help] [--version]
    EOT

    def ctl
      parse_options
      send("do_#{ALIASES[ARGV.shift]}")
    end

    def self.cmd(name, short, desc, args = nil, default = nil)
      if name.is_a?(Array)
        m, f, k = name
        name, short = "#{m}#{k}", "#{f}#{short}"
        class_eval %Q{private; def do_#{name}; #{m}(:#{k}); end}
      end

      if args
        desc = [desc, args = "Arguments: #{args}"]
        args << " (Default: #{default})" if default
      end

      COMMANDS[name], ALIASES[short] = desc, name
    end

    { config: %w[c configuration],
      lang:   %w[l language],
      dict:   %w[d dictionary dictionaries],
      store:  %w[s store],
      sample: %w[e sample\ text\ file]
    }.each { |n, (s, q, r)|
      t = n == :store

      cmd([:list,  :l, n], s, "List available #{r || "#{q}s"}", '[name...]') if !t
      cmd([:find,  :f, n], s, "Find #{q} in Lingo search path",      'name')
      cmd([:copy,  :c, n], s, "Copy #{q} to local Lingo directory",  'name') if !t
      cmd([:clear, :c, n], s, 'Remove store files to force rebuild', 'name') if  t
    }

    { demo:    [:d, 'Initialize demo directory', '[path]', 'current directory'],
      rackup:  [:r, 'Print path to rackup file', 'name'],
      path:    [:p, 'Print search path for dictionaries and configurations'],
      help:    [:h, 'Print help for available commands'],
      version: [:v, 'Print Lingo version number']
    }.each { |n, (s, *a)| cmd(n.to_s, s.to_s, *a) }

    private

    def list(what, doit = true)
      names = Regexp.union(*ARGV.empty? ? '' : ARGV)

      Lingo.list(what, path: path_for_scope).select { |file|
        File.basename(file) =~ names ? doit ? puts(file) : true : false
      }
    end

    def find(what, doit = true)
      name = ARGV.shift or missing_arg(:name)
      no_args

      file = Lingo.find(what, name, path: path_for_scope) { usage }
      doit ? puts(file) : file
    end

    def copy(what)
      usage('Source and target are the same.') if OPTIONS[:scope] == :local

      source = find(what, false)
      target = File.join(path_for_scope(:local), Lingo.basepath(what, source))

      usage('Source and target are the same.') if source == target

      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(source, target, verbose: true)
    end

    def do_clearstore
      store = Dir["#{find(:store, false)}.*"]
      FileUtils.rm(store, verbose: true) unless store.empty?
    end

    def do_demo
      OPTIONS.update(path: ARGV.shift, scope: :system)
      no_args

      copy_list(:config) { |i| !File.basename(i).start_with?('test') }
      copy_list(:lang)
      copy_list(:dict)   { |i|  File.basename(i).start_with?('user') }
      copy_list(:sample)
    end

    def do_rackup(doit = true)
      name = ARGV.shift or missing_arg(:name)
      no_args

      require 'lingo/app'

      if file = Lingo::App.rackup(name)
        doit ? puts(file) : file
      else
        usage("Invalid app name `#{name.inspect}'.")
      end
    end

    def do_path
      no_args
      puts path_for_scope || PATH
    end

    def do_help(opts = nil)
      no_args

      msg = opts ? [opts, 'Commands:'] : []

      aliases = Hash.new { |h, k| h[k] = [] }
      ALIASES.each { |k, v| aliases[v] << k }

      COMMANDS.each { |c, (d, *e)|
        a = aliases[c]
        c = "#{c} (#{a.join(', ')})" unless a.empty?

        if opts
          msg << "    %-#{OPTWIDTH}s %s" % [c, d]
        else
          msg << "#{c}" << "  - #{d}"
          e.each { |i| msg <<  "  + #{i}" }
        end
      }

      abort msg.join("\n")
    end

    def do_version(doit = true)
      no_args

      msg = "Lingo v#{Lingo::VERSION}"
      doit ? puts(msg) : msg
    end

    def parse_options
      OptionParser.new(USAGE, OPTWIDTH) { |opts|
        opts.separator ''
        opts.separator 'Scope options:'

        opts.on('--system', 'Restrict command to the system-wide Lingo directory') {
          OPTIONS[:scope] = :system
        }

        opts.on('--global', "Restrict command to the user's personal Lingo directory") {
          OPTIONS[:scope] = :global
        }

        opts.on('--local', 'Restrict command to the local Lingo directory') {
          OPTIONS[:scope] = :local
        }

        opts.separator ''
        opts.separator 'Generic options:'

        opts.on('-h', '--help', 'Print this help message and exit') {
          do_help(opts)
        }

        opts.on('--version', 'Print program version and exit') {
          abort "#{PROGNAME} v#{VERSION} (#{do_version(false)})"
        }
      }.parse!
    end

    def path_for_scope(scope = OPTIONS[:scope])
      case scope
        when :system then [BASE]
        when :global then [HOME]
        when :local  then [OPTIONS[:path] || CURR]
        when nil
        else usage("Invalid scope `#{scope.inspect}'.")
      end
    end

    def usage(msg = nil)
      abort "#{"#{PROGNAME}: #{msg}\n\n" if msg}#{USAGE}"
    end

    alias_method :do_usage, :usage

    def missing_arg(arg)
      usage("Required argument `#{arg}' missing.")
    end

    def no_args
      usage('Too many arguments.') unless ARGV.empty?
    end

    def copy_list(what)
      files = list(what, false)
      files.select! { |i| yield i } if block_given?
      files.each { |file| ARGV.replace([file]); copy(what) }
    end

  end

  def self.ctl
    Ctl.ctl
  rescue => err
    raise if $VERBOSE
    abort "#{err.backtrace.first}: #{err} (#{err.class})"
  end

end
