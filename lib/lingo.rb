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

require 'unicode'
require 'stringio'
require 'pathname'
require 'fileutils'
require 'nuggets/file/ext'
require 'nuggets/hash/seen'
require 'nuggets/env/user_home'
require 'nuggets/string/camelscore'

class Lingo

  # The system-wide Lingo directory (+LINGO_BASE+).
  BASE = ENV['LINGO_BASE'] || File.expand_path('../..', __FILE__)

  # The user's personal Lingo directory (+LINGO_HOME+).
  HOME = ENV['LINGO_HOME'] || File.join(ENV.user_home, '.lingo')

  # The local Lingo directory (+LINGO_CURR+).
  CURR = ENV['LINGO_CURR'] || '.'

  # The search path for Lingo dictionary and configuration files.
  PATH = ENV['LINGO_PATH'].nil? ? [CURR, HOME, BASE] :
         ENV['LINGO_PATH'].split(File::PATH_SEPARATOR)

  ENV['LINGO_PLUGIN_PATH'] ||= File.join(HOME, 'plugins')

  # Map of file types to their standard location and file extension.
  FIND_OPTIONS = {
    config: { dir: 'config', ext: 'cfg'  },
    dict:   { dir: 'dict',   ext: 'txt'  },
    lang:   { dir: 'lang',   ext: 'lang' },
    store:  { dir: 'store',  ext:  nil   },
    sample: { dir: 'txt',    ext: 'txt'  }
  }

  # Default encoding
  Encoding.default_external = Encoding.default_internal = ENC = 'UTF-8'.freeze

  SEP_RE = %r{[; ,|]}

  class << self

    def talk(*args)
      new(*args).talk
    end

    def call(cfg = find(:config, 'lingo-call'), args = [], &block)
      Call.new(['-c', cfg, *args]).call(&block)
    end

    def list(type, options = {})
      options = options_for(type, options)

      glob, list = file_with_ext('*', options), []
      glob = File.join('??', glob) if type == :dict

      walk(path = path_for(options), options) { |dir|
        Dir[File.join(dir, glob)].sort!.each { |file|
          pn = Pathname.new(file)
          list << realpath_for(pn, path) if pn.file?
        }
      }

      list
    end

    def find(type, file, options = {})
      if options.is_a?(Array)
        path    = options
        options = options_for(type)
      else
        options = options_for(type, options)
        path    = path_for(options)
      end

      type = :file if type != :store
      send("find_#{type}", file, path, options)
    rescue RuntimeError, Errno::ENOENT => err
      block_given? ? yield(err) : raise
    end

    def basename(type, file)
      dir, name = File.split(file)
      type != :dict ? name : File.join(File.basename(dir), name)
    end

    def basepath(type, file)
      File.join(options_for(type)[:dir], basename(type, file))
    end

    def append_path(*path)
      include_path(path)
    end

    def prepend_path(*path)
      include_path(path, true)
    end

    def get_const(name, klass = self)
      klass.const_get(name.camelcase)
    rescue NameError
      raise NameNotFoundError.new(klass, name)
    end

    private

    def include_path(path, pre = false)
      PATH.insert(pre ? 0 : -1, *path.map! { |i| i.to_s })
    end

    def find_file(file, path, options)
      if glob = options[:glob]
        file = File.chomp_ext(file)
        options[:ext] ||= '*'
      end

      file = file_with_ext(file, options)
      pn   = Pathname.new(file).cleanpath

      if pn.relative?
        walk(path, options) { |dir|
          pn2 = pn.expand_path(dir)
          ex  = pn2.exist?

          pn2 = Pathname.glob(pn2).first if glob && !ex
          pn  = pn2 and break if glob ? pn2 : ex
        }
      end

      realpath_for(pn, path)
    rescue Errno::ENOENT
      raise unless relax = options[:relax]
      relax.respond_to?(:[]) ? relax[file] : file
    end

    def find_store(file, path, options)
      base = basename(:dict, find(:dict, file, path) {
        raise SourceFileNotFoundError.new(nil, find_file(file, path,
          options.merge(glob: true, relax: lambda { |_file|
            raise SourceFileNotFoundError.new(file, _file)
          })
        ))
      })

      walk(path.reverse, options, false) { |dir|
        Pathname.new(dir).ascend { |i|
          begin
            stat = i.stat

            break true if stat.file? || !stat.writable?
            return File.chomp_ext(File.join(dir, base))
          rescue Errno::ENOENT
          end
        }
      }

      raise NoWritableStoreError.new(file, path)
    end

    def options_for(type, options = {})
      if find_options = FIND_OPTIONS[type]
        options = find_options.merge(options)
      else
        raise ArgumentError, "Invalid type `#{type.inspect}'", caller(1)
      end
    end

    def path_for(options)
      options[:path] || PATH
    end

    def file_with_ext(file, options)
      ext = options[:ext]
      ext && File.extname(file).empty? ? "#{file}.#{ext}" : file
    end

    def walk(path, options, legacy = true)
      dirs, seen = [options[:dir].to_s], Hash.seen
      dirs << '' if legacy
      dirs.uniq!

      path.each { |d|
        next if seen[d = File.expand_path(d)]
        dirs.each { |i| yield File.join(d, i) } or break
      }
    end

    def realpath_for(pn, path)
      pn.realpath(path.first).to_s
    end

    def require_optional(lib)
      require lib unless ENV["LINGO_NO_#{lib.upcase}"]
    rescue LoadError
    end

  end

  def initialize(*args)
    Debug.ps(:lingo_new)

    @config_args = args
    reset(false)
  end

  attr_reader :dictionaries

  def config
    @config ||= Config.new(*@config_args)
  rescue => err
    raise ConfigLoadError.new(err)
  end

  def dictionary_config
    @dictionary_config ||= config['language/dictionary']
  end

  def database_config(id)
    dictionary_config['databases'][id].tap { |cfg|
      raise NoDatabaseConfigError.new(id) unless cfg
      raise InvalidDatabaseConfigError.new(id) unless cfg.key?('name')
    }
  end

  def lexical_hash(src)
    @lexical_hash[src]
  end

  def talk
    Debug.profile(config['profile']) {
      invite
      start
    }

    Debug.ps(:lingo_talk)
  ensure
    reset
  end

  def invite(list = config['meeting/attendees'])
    supplier   = Hash.new { |h, k| h[k] = [] }
    subscriber = Hash.new { |h, k| h[k] = [] }

    last_link, auto_link = '', 0

    list.each { |hash|
      name = (name_key = hash.keys.first).camelcase

      cfg = (config["language/attendees/#{name.downcase}"] || {})
        .merge(hash.values.first).update('name' => name)

      %w[in out].each { |key| (cfg[key] ||= '').downcase! }

      cfg['in']  = last_link                     if cfg['in'].empty?
      cfg['out'] = "auto_link-#{auto_link += 1}" if cfg['out'].empty?
      last_link  = cfg['out']

      @attendees << attendee = Attendee.const_get(name).new(cfg, self)

      unless name == (real = attendee.class.name.split('::').last)
        config.deprecate(name_key, real.underscore, attendee, :name)
      end

      { 'in' => subscriber, 'out' => supplier }.each { |key, target|
        cfg[key].split(SEP_RE).each { |ch| target[ch] << attendee }
      }
    }

    supplier.each { |ch, attendees| attendees.each { |att|
      att.subscribers.concat(subscriber[ch])
    } }
  end

  def start
    @attendees.first.control(:TALK)
  end

  def reset(close = true)
    dictionaries.each { |i| i.close } if close
    @dictionaries, @attendees = [], []
    @lexical_hash = Hash.new { |h, k| h[k] = Language::LexicalHash.new(k, self) }
  end

  def warn(*msg)
    config.warn(*msg)
  end

end

require_relative 'lingo/call'
require_relative 'lingo/error'
require_relative 'lingo/debug'
require_relative 'lingo/config'
require_relative 'lingo/progress'
require_relative 'lingo/database'
require_relative 'lingo/language'
require_relative 'lingo/attendee'
require_relative 'lingo/version'

require 'nuggets/pluggable'
Nuggets::Pluggable.load_plugins_for(Lingo)
