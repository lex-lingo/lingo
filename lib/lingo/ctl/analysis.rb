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

require 'csv'

class Lingo

  module Ctl

    { stats: [:s, 'Extract statistics from analysis file', 'path'],
      trans: [:t, 'Transpose columns and rows of analysis file', 'path'],
      diff:  [:d, 'Show differences between two analysis files', 'path1 path2']
    }.each { |n, (s, *a)| cmd("analysis#{n}", "a#{s}", *a) }

    private

    def do_analysisstats
      path = ARGV.shift or missing_arg(:path)
      no_args

      abort "No such file: #{path}" unless File.exist?(path)

      require 'nuggets/array/histogram'

      name, stats, patterns = path.chomp(File.extname(path)),
        Hash.nest { [] }, Hash.nest { [] }

      CSV.foreach(path, headers: true) { |row|
        if token = row['token']
          stats[:tokens] << token
        elsif word = row['word']
          stats[:words] << word
          pattern = row['pattern'] and patterns[word] << pattern
        end
      }

      write = lambda { |key, &block|
        overwrite?(file = "#{name}.#{key}.csv") &&
          puts("#{file}: #{CSV.open(file, 'wb', &block)}") }

      stats.each { |key, value| write.(key) { |csv| value.histogram.sort
        .tap { |h| csv << h.map(&:shift) << h.flatten! }; value.size } }

      write.(:patterns) { |csv|
        patterns = patterns.sort.map { |key, value| [key, value.histogram] }

        csv << headers = patterns.map(&:last)
          .flat_map(&:keys).uniq.sort.unshift(word = 'word')

        patterns.each { |key, value| value.default = nil
          csv << value.update(word => key).values_at(*headers) }

        headers.size - 1
      }
    end

    def do_analysistrans
      path = ARGV.shift or missing_arg(:path)
      no_args

      abort "No such file: #{path}" unless File.exist?(path)

      return unless overwrite?(file =
        "#{path.chomp(File.extname(path))}.transposed.csv")

      rows = Hash.nest { [] }

      CSV.foreach(path, headers: true) { |row|
        rows[row['token'] || row['word']] << row['string'] }

      rows = rows.sort; iter = rows.each_index

      size = CSV.open(file, 'wb') { |csv|
        csv << rows.map(&:shift)

        rows.flatten!(1).map(&:size).max.times { |j|
          csv << iter.map { |i| rows[i][j] } }
      }

      puts "#{file}: #{size}"
    end

    def do_analysisdiff
      path1 = ARGV.shift or missing_arg(:path1)
      path2 = ARGV.shift or missing_arg(:path2)
      no_args

      abort "No such file: #{path1}" unless File.exist?(path1)
      abort "No such file: #{path2}" unless File.exist?(path2)

      abort 'Not implemented yet.'
    end

  end

end
