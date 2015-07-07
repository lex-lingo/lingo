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

    { stats: [:s, 'Extract statistics from analysis file(s)', 'path...'],
      trans: [:t, 'Transpose columns and rows of analysis file(s)', 'path...']
    }.each { |n, (s, *a)| cmd("analysis#{n}", "a#{s}", *a) }

    private

    def do_analysisstats
      require 'nuggets/array/histogram'

      paths, write = paths_write
      stats, patts = Hash.array(1), Hash.array(1)

      csv_foreach(paths) { |path, _, token, word, pattern|
        token ? stats[:tokens][path] << token : word ? begin
          stats[:words][path] << word
          patts[word][path] << pattern if pattern
        end : nil
      }

      stats.each { |k, h| write.(k) { |csv|
        csv << ['file', *c = columns(g = histograms(h))]
        histograms_to_csv(csv, c, g)
        h.values.map(&:size)
      } }

      write.(:patterns) { |csv|
        csv << ['file', 'word', *c = columns(patts, :values)]
        patts.sort.each { |k, h| histograms_to_csv(csv, c, histograms(h), k) }
        c.size - 1
      }
    end

    def do_analysistrans
      paths, write = paths_write

      rows, comm, more, less = Hash.array(1), {}, Hash.array(1), Hash.array(1)

      csv_foreach(paths) { |path, string, token, word, _|
        rows[token || word][path] << string }

      c = rows.keys.sort.each { |k|
        a = (h = rows[k]).first.last

        paths.size == 1 ? comm[k] = a : begin
          comm[k] = a & (o = h.drop(1)).flat_map(&:last)
          o.each { |path, b| more[path][k] = b - a; less[path][k] = a - b }
        end
      }

      rows.clear

      write.(:transpose) { |csv| transpose_csv(csv, c, comm) }

      { transmore: more, transless: less }.each { |k, v| v.each { |path, h|
        csv_writer(path, *paths).(k) { |csv| transpose_csv(csv, c, h) } } }
    end

    def paths_write
      ARGV.empty? ? missing_arg(:path) : [a = ARGV.each { |x|
        abort "No such file: #{x}" unless File.exist?(x) }, csv_writer(*a)]
    end

    def csv_writer(*paths)
      name = File.join(File.dirname(paths.first), paths.map { |path|
        File.basename(path.chomp(File.extname(path))) }.uniq.join('-'))

      lambda { |key, &block| overwrite?(file = "#{name}.#{key}.csv") &&
        puts("#{file}: #{Array(CSV.open(file, 'wb', &block)).join(' / ')}") }
    end

    def csv_foreach(paths)
      paths.each { |path| CSV.foreach(path, headers: true) { |row|
        yield path, *row.values_at(*%w[string token word pattern]) } }
    end

    def columns(hash, map = :keys)
      hash.values.map(&map).flatten.uniq.sort
    end

    def histograms(hash)
      hash.each_with_object({}) { |(k, v), h|
        h[k] = v.histogram.tap { |x| x.default = nil } }
    end

    def histograms_to_csv(csv, columns, histograms, *args)
      histograms.each { |key, histogram|
        others = histograms.values_at(*histograms.keys - [key])
        others = [{}] if others.empty?

        csv << args.dup.unshift(key).concat(columns.map { |header|
          value = histogram[header] or next
          value if others.any? { |other| other[header] != value }
        })
      }
    end

    def transpose_csv(csv, columns, rows)
      csv << columns; values = rows.values_at(*columns); rows.clear
      values.map(&:size).max.times { |i| csv << values.map { |v| v[i] } }
    end

  end

end
