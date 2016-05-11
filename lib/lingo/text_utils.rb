# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2016 John Vorhauer, Jens Wille                           #
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

require 'nuggets/file/ext'
require 'nuggets/string/format'

class Lingo

  module TextUtils

    STDIN_EXT = %w[STDIN -].freeze

    STDOUT_EXT = %w[STDOUT -].freeze

    GZIP_RE = %r{\.gz(?:ip)?\z}i

    private

    def stdin?(path)
      STDIN_EXT.include?(path)
    end

    def stdout?(path)
      STDOUT_EXT.include?(path)
    end

    def open_stdin
      stdin = set_encoding(lingo.config.stdin)
      @progress ? StringIO.new(stdin.read) : stdin
    end

    def open_stdout
      set_encoding(lingo.config.stdout)
    end

    def open_path(path, mode = 'rb')
      path =~ GZIP_RE ? open_gzip(path, mode) : open_file(path, mode)
    end

    def open_file(path, mode)
      File.open(path, mode, encoding: bom_encoding(mode))
    end

    def open_gzip(path, mode)
      require_lib('zlib')

      case mode
        when 'r', 'rb'
          @progress = false
          Zlib::GzipReader.open(path, encoding: @encoding)
        when 'w', 'wb'
          Zlib::GzipWriter.open(path, encoding: @encoding)
        else
          raise ArgumentError, 'invalid access mode %s' % mode
      end
    end

    def get_path(path, ext)
      set_ext(path, ext).format { |directive|
        case directive
          when 'd', t = 't' then Time.now.strftime(t ? '%H%M%S' : '%Y%m%d')
          when 'c', l = 'l' then File.chomp_ext(File.basename(
            lingo.config.send("#{l ? :lang : :config}_file")))
        end
      }
    end

    def set_ext(path, ext)
      File.set_ext(path.sub(GZIP_RE, ''), ".#{ext}")
    end

    def set_encoding(io, encoding = @encoding)
      io.set_encoding(encoding)
      io
    end

    def bom_encoding(mode = 'r', encoding = @encoding)
      (mode.include?('r') || mode.include?('+')) &&
        encoding.name.start_with?('UTF-') ? "BOM|#{encoding}" : encoding
    end

  end

end