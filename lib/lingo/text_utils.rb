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

    DEFAULT_MODE = 'rb'.freeze

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

    def overwrite?(path, unlink = false)
      !File.exist?(path) || if agree?("#{path} already exists. Overwrite?")
        File.unlink(path) if unlink
        true
      end
    end

    def agree?(msg)
      print "#{msg} (y/n) [n]: "

      case stdin.gets.chomp
        when /\Ano?\z/i, ''  then nil
        when /\Ay(?:es)?\z/i then true
        else puts 'Please enter "yes" or "no".'; agree?(msg)
      end
    rescue Interrupt
      abort ''
    end

    def stdin
      respond_to?(:lingo, true) ? lingo.config.stdin : $stdin
    end

    def stdout
      respond_to?(:lingo, true) ? lingo.config.stdout : $stdout
    end

    def open(path, mode = nil, encoding = nil, &block)
      mode ||= DEFAULT_MODE

      _yield_obj(case mode
        when /r/ then stdin?(path) ? open_stdin(encoding) : File.exist?(path) ?
          open_path(path, mode, encoding) : raise(FileNotFoundError.new(path))
        when /w/ then stdout?(path) ? open_stdout(encoding) : overwrite?(path) ?
          open_path(path, mode, encoding) : raise(FileExistsError.new(path))
      end, &block)
    end

    def open_csv(path, mode = nil, options = {}, encoding = nil, &block)
      _require_lib('csv')

      open(path, mode, encoding) { |io|
        _yield_obj(CSV.new(io, options), &block) }
    end

    def open_stdin(encoding = nil)
      io = set_encoding(stdin, encoding)
      @progress ? StringIO.new(io.read) : io
    end

    def open_stdout(encoding = nil)
      set_encoding(stdout, encoding)
    end

    def open_path(path, mode = nil, encoding = nil)
      mode ||= DEFAULT_MODE

      path =~ GZIP_RE ?
        open_gzip(path, mode, encoding) :
        open_file(path, mode, encoding)
    end

    def open_file(path, mode = nil, encoding = nil)
      File.open(path, mode ||= DEFAULT_MODE,
        encoding: bom_encoding(mode, encoding))
    end

    def open_gzip(path, mode = nil, encoding = nil)
      _require_lib('zlib')

      case mode ||= DEFAULT_MODE
        when 'r', 'rb'
          @progress = false
          Zlib::GzipReader
        when 'w', 'wb'
          Zlib::GzipWriter
        else
          raise ArgumentError, 'invalid access mode %s' % mode
      end.open(path, encoding: get_encoding(encoding))
    end

    def foreach(path, encoding = nil)
      open(path, nil, encoding) { |io|
        io.each { |line| line.chomp!; yield line } }
    end

    def foreach_csv(path, options = {}, encoding = nil, &block)
      open_csv(path, nil, options, encoding) { |csv| csv.each(&block) }
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

    def set_encoding(io, encoding = nil)
      io.set_encoding(get_encoding(encoding))
      io
    end

    def get_encoding(encoding = nil, iv = :@encoding)
      encoding ||
        (instance_variable_defined?(iv) ? instance_variable_get(iv) : nil)
    end

    def bom_encoding(mode = 'r', encoding = nil)
      encoding = get_encoding(encoding)

      encoding && (mode.include?('r') || mode.include?('+')) &&
        encoding.name.start_with?('UTF-') ? "BOM|#{encoding}" : encoding
    end

    private

    def _require_lib(lib)
      respond_to?(:require_lib, true) ? require_lib(lib) : require(lib)
    end

    def _yield_obj(obj)
      !block_given? ? obj : begin
        yield obj
      ensure
        obj.close
      end
    end

  end

end
