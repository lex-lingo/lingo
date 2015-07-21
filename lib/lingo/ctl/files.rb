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

  module Ctl

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

    private

    def list(what, doit = true)
      names = Regexp.union(*ARGV.empty? ? '' : ARGV)

      Lingo.list(what, path: path_for_scope).select { |file|
        File.basename(file) =~ names ? doit ? puts(file) : true : false
      }
    end

    def find(what, doit = true, path = path_for_scope)
      name = ARGV.shift or missing_arg(:name)
      no_args

      file = Lingo.find(what, name, path: path) { |err| usage(err) }
      doit ? puts(file) : file
    end

    def copy(what)
      usage('Source and target are the same.') if OPTIONS[:scope] == :local

      local_path = path_for_scope(:local)

      source = find(what, false, path_for_scope || Lingo::PATH - local_path)
      target = File.expand_path(Lingo.basepath(what, source), local_path)

      usage('Source and target are the same.') if source == target

      return unless overwrite?(target)

      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(source, target, verbose: true)
    end

    def do_clearstore
      store = Dir["#{find(:store, false)}.*"]
      FileUtils.rm(store, verbose: true) unless store.empty?
    end

  end

end
