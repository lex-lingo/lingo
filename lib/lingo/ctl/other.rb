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

require 'zip'
Zip.unicode_names = true

class Lingo

  module Ctl

    { demo:    [:d, 'Initialize demo directory', '[path]', 'current directory'],
      archive: [:a, 'Create archive of directory', '[path]', 'current directory'],
      rackup:  [:r, 'Print path to rackup file', 'name'],
      path:    [:p, 'Print search path for dictionaries and configurations'],
      help:    [:h, 'Print help for available commands'],
      version: [:v, 'Print Lingo version number']
    }.each { |n, (s, *a)| cmd(n.to_s, s.to_s, *a) }

    private

    def do_archive
      OPTIONS.update(path: ARGV.shift, scope: :local)
      no_args

      source = File.expand_path(path_for_scope.first)
      target = "#{source}.zip"

      abort "No such directory: #{source}" unless Dir.exist?(source)

      return unless overwrite?(target, true)

      base, name = File.split(source)

      Dir.chdir(base) {
        Zip::File.open(target, Zip::File::CREATE) { |zipfile|
          Dir[File.join(name, '**', '*')].each { |file|
            zipfile.add(file, file)
          }
        }
      }

      puts "Directory successfully archived at `#{target}'."
    end

    def do_demo
      OPTIONS.update(path: ARGV.shift, scope: :system)
      no_args

      path = path_for_scope(:local).first

      copy_list(:config) { |i| !File.basename(i).start_with?('test') }
      copy_list(:lang)
      copy_list(:dict)   { |i|  File.basename(i).start_with?('user') }
      copy_list(:sample)

      puts "Demo directory successfully initialized at `#{path}'."
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

      aliases = Hash.nest { [] }
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

    def copy_list(what)
      files = list(what, false)
      files.select! { |i| yield i } if block_given?
      files.each { |file| ARGV.replace([file]); copy(what) }
    end

  end

end
