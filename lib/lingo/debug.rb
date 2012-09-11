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

class Lingo

  module Debug

    extend self

    PS_COMMAND = ENV['LINGO_PS_COMMAND'] || '/bin/ps'
    PS_COLUMNS = ENV['LINGO_PS_COLUMNS'] || 'vsz,rss,sz,%mem,%cpu,time,etime,pid'

    PS_RE = File.executable?(PS_COMMAND) ? %r{\A#{ENV['LINGO_DEBUG_PS']}\z} : nil

    PS_NO_HEADING = Hash.new { |h, k| h[k] = true; false }

    def ps(name)
      system(PS_COMMAND,
        '-o', PS_COLUMNS,
        "--#{'no-' if PS_NO_HEADING[name]}heading",
        Process.pid.to_s) if name =~ PS_RE
    end

    def profile(base)
      return yield unless base

      require 'ruby-prof'

      result = RubyProf.profile { yield }
      result.eliminate_methods! [/\b(?:Gem|HighLine)\b/,
        /\A(?:Benchmark|FileUtils|Pathname|Util)\b/]

      if base.is_a?(IO)
        RubyProf::FlatPrinter.new(result).print(base)
      else
        FileUtils.mkdir_p(File.dirname(base))

        mode = ENV['RUBY_PROF_MEASURE_MODE']
        base += "-#{mode}" if mode && !mode.empty?

        {
          :txt   => :FlatPrinter,
          :lines => :FlatPrinterWithLineNumbers,
          :html  => :GraphHtmlPrinter,
          :stack => :CallStackPrinter
        }.each { |ext, name|
          File.open("#{base}.#{ext}", 'a+', encoding: ENC) { |f|
            RubyProf.const_get(name).new(result).print(f)
          }
        }
      end
    end

  end

end
