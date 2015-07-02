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

require 'optparse'

class Lingo

  module Ctl

    extend self

    PROG, VERSION, OPTWIDTH = $0, '0.0.3', 21
    PROGNAME, OPTIONS = File.basename(PROG), {}

    COMMANDS, ALIASES = {}, Hash.nest { |k|
      COMMANDS.key?(k) ? k : 'usage'
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

    private

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

    def overwrite?(target, unlink = false)
      !File.exist?(target) || if agree?("#{target} already exists. Overwrite?")
        File.unlink(target) if unlink
        true
      end
    end

    def agree?(msg)
      print "#{msg} (y/n) [n]: "

      case answer = $stdin.gets.chomp
        when /\Ano?\z/i, ''  then nil
        when /\Ay(?:es)?\z/i then true
        else puts 'Please enter "yes" or "no".'; agree?(msg)
      end
    rescue Interrupt
      abort ''
    end

  end

  def self.ctl
    Ctl.ctl
  rescue => err
    raise if $VERBOSE
    abort "#{err.backtrace.first}: #{err} (#{err.class})"
  end

end

require_relative 'ctl/files'
require_relative 'ctl/analysis'
require_relative 'ctl/other'
