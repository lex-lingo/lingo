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

require 'stringio'
require 'benchmark'
require 'nuggets/file/ext'
require 'nuggets/env/user_home'
require 'nuggets/numeric/duration'

require_relative 'lingo/call'
require_relative 'lingo/error'
require_relative 'lingo/config'
require_relative 'lingo/core_ext'
require_relative 'lingo/cachable'
require_relative 'lingo/reportable'
require_relative 'lingo/agenda_item'
require_relative 'lingo/database'
require_relative 'lingo/language'
require_relative 'lingo/attendee'
require_relative 'lingo/version'

class Lingo

  include Error

  # The system-wide Lingo directory (+LINGO_BASE+).
  BASE = ENV['LINGO_BASE'] || File.expand_path('../..', __FILE__)

  # The user's personal Lingo directory (+LINGO_HOME+).
  HOME = ENV['LINGO_HOME'] || File.join(ENV.user_home, '.lingo')

  # The local Lingo directory (+LINGO_CURR+).
  CURR = ENV['LINGO_CURR'] || '.'

  # The search path for Lingo dictionary and configuration files.
  PATH = ENV['LINGO_PATH'] || [CURR, HOME, BASE].join(File::PATH_SEPARATOR)

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
  ENC = 'UTF-8'.freeze

  STRING_SEPARATOR_RE = %r{[; ,|]}

  class << self

    def talk(*args)
      new(*args).talk
    end

    def call(cfg = find(:config, 'lingo-call'), args = [], &block)
      Call.new(['-c', cfg, *args]).call(&block)
    end

    def list(type, options = {})
      options = options_for(type, options)
      path    = path_for(options)

      glob = file_with_ext('*', options)
      glob = File.join('??', glob) if type == :dict

      [].tap { |list| walk(path, options) { |dir|
        Dir[File.join(dir, glob)].sort.each { |file|
          pn = Pathname.new(file)
          list << realpath_for(pn, path) if pn.file?
        }
      } }
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

    private

    def find_file(file, path, options)
      pn = Pathname.new(file_with_ext(file, options)).cleanpath

      walk(path, options) { |dir|
        pn2 = pn.expand_path(dir)
        pn = pn2 and break if pn2.exist?
      } if pn.relative?

      realpath_for(pn, path)
    end

    def find_store(file, path, options)
      base = basename(:dict, find(:dict, file, path))

      walk(path.reverse, options, false) { |dir|
        Pathname.new(dir).ascend { |r|
          break  true                                 if r.file?
          return File.chomp_ext(File.join(dir, base)) if r.writable?
          break  true                                 if r.exist?
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
      options[:path] || PATH.split(File::PATH_SEPARATOR)
    end

    def file_with_ext(file, options)
      ext = options[:ext]
      ext && File.extname(file).empty? ? "#{file}.#{ext}" : file
    end

    def walk(path, options, legacy = true)
      dirs = [options[:dir].to_s]
      dirs << '' if legacy
      dirs.uniq!

      seen = Hash.new { |h, k| h[k] = true; false }

      path.each { |d|
        next if seen[d = File.expand_path(d)]
        dirs.each { |i| yield File.join(d, i) } or break
      }
    end

    def realpath_for(pn, path)
      pn.realpath(path.first).to_s
    end

  end

  attr_reader :dictionaries, :report_status, :report_time

  def initialize(*args)
    @config_args = args
    reset(false)
  end

  def config
    @config ||= Config.new(*@config_args)
  end

  def dictionary_config
    @dictionary_config ||= config['language/dictionary']
  rescue => err
    raise ConfigLoadError.new(err)
  end

  def database_config(id)
    dictionary_config['databases'][id].tap { |cfg|
      raise NoDatabaseConfigError.new(id) unless cfg
      raise InvalidDatabaseConfigError.new(id) unless cfg.has_key?('name')
    }
  end

  def lexical_hash(src)
    @lexical_hash[src]
  end

  def talk
    invite
    start
  ensure
    reset
  end

  def invite(list = config['meeting/attendees'])
    supplier   = Hash.new { |h, k| h[k] = [] }
    subscriber = Hash.new { |h, k| h[k] = [] }

    last_link, auto_link = '', 0

    list.each { |hash|
      # {'attendee' => {'name'=>'Attendee', 'in'=>'nase', 'out'=>'ohr', 'param'=>'hase'}}
      cfg = hash.values.first.merge('name' => hash.keys.first.capitalize)

      %w[in out].each { |key| (cfg[key] ||= '').downcase! }

      cfg['in']  = last_link                         if cfg['in'].empty?
      cfg['out'] = "auto_link_out_#{auto_link += 1}" if cfg['out'].empty?
      last_link  = cfg['out']

      data = config["language/attendees/#{cfg['name'].downcase}"]
      cfg.update(data) if data

      attendee = Attendee.const_get(cfg['name']).new(cfg, self)
      @attendees << attendee

      cfg['in'].split(STRING_SEPARATOR_RE).each { |interest|
        subscriber[interest] << attendee
      }
      cfg['out'].split(STRING_SEPARATOR_RE).each { |theme|
        supplier[theme] << attendee
      }
    }

    supplier.each { |channel, attendees| attendees.each { |att|
      att.add_subscriber(subscriber[channel])
    } }
  end

  def start(report_status = config['status'], report_time = config['perfmon'])
    @report_status, @report_time = report_status, report_time

    time = Benchmark.realtime {
      @attendees.first.listen(AgendaItem.new(Attendee::STR_CMD_TALK))
    }

    if report_status || report_time
      config.stderr.puts "Require protocol...\n#{separator = '-' * 61}"
      @attendees.first.listen(AgendaItem.new(Attendee::STR_CMD_STATUS))
      config.stderr.puts "#{separator}\nThe duration of the meeting was #{time.to_hms(2)}"
    end
  end

  def reset(close = true)
    dictionaries.each(&:close) if close
    @dictionaries, @attendees = [], []
    @lexical_hash = Hash.new { |h, k| h[k] = Language::LexicalHash.new(k, self) }
  end

end

require 'nuggets/util/pluggable'
Util::Pluggable.load_plugins_for(Lingo)
