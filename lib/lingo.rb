# encoding: utf-8

#--
# LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
# Mehrworterkennung und Relationierung.
#
# Copyright (C) 2005-2007 John Vorhauer
# Copyright (C) 2007-2012 John Vorhauer, Jens Wille
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
# For more information visit http://www.lex-lingo.de or contact me at
# welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
# Lex Lingo rules from here on
#++

require 'stringio'
require 'benchmark'
require 'nuggets/file/ext'
require 'nuggets/env/user_home'
require 'nuggets/numeric/duration'

require_relative 'lingo/config'
require_relative 'lingo/attendees'
require_relative 'lingo/attendee/abbreviator'
require_relative 'lingo/attendee/debugger'
require_relative 'lingo/attendee/decomposer'
require_relative 'lingo/attendee/dehyphenizer'
require_relative 'lingo/attendee/multiworder'
require_relative 'lingo/attendee/noneword_filter'
require_relative 'lingo/attendee/objectfilter'
require_relative 'lingo/attendee/variator'
require_relative 'lingo/attendee/sequencer'
require_relative 'lingo/attendee/synonymer'
require_relative 'lingo/attendee/textreader'
require_relative 'lingo/attendee/textwriter'
require_relative 'lingo/attendee/tokenizer'
require_relative 'lingo/attendee/vector_filter'
require_relative 'lingo/attendee/wordsearcher'
require_relative 'lingo/version'

class Lingo

  # The system-wide Lingo directory (+LINGO_BASE+).
  BASE = ENV['LINGO_BASE'] || File.expand_path('../..', __FILE__)

  # The user's personal Lingo directory (+LINGO_HOME+).
  HOME = ENV['LINGO_HOME'] || File.join(ENV.user_home, '.lingo')

  # The local Lingo directory (+LINGO_CURR+).
  CURR = ENV['LINGO_CURR'] || '.'

  # The search path for Lingo dictionary and configuration files.
  PATH = ENV['LINGO_PATH'] || [CURR, HOME, BASE].join(File::PATH_SEPARATOR)

  ENV['LINGO_PLUGIN_PATH'] ||= File.join(HOME, 'plugins')

  FIND_OPTIONS = {
    config: { dir: 'config', ext: 'cfg'  },
    dict:   { dir: 'dict',   ext: 'txt'  },
    lang:   { dir: 'lang',   ext: 'lang' },
    store:  { dir: 'store',  ext: nil    },
    sample: { dir: 'txt',    ext: 'txt'  }
  }

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

      raise 'No writable store found in search path'
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
  end

  def database_config(id)
    dictionary_config['databases'][id]
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

      cfg['in'].split(STRING_SEPERATOR_PATTERN).each { |interest|
        subscriber[interest] << attendee
      }
      cfg['out'].split(STRING_SEPERATOR_PATTERN).each { |theme|
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
      @attendees.first.listen(AgendaItem.new(STR_CMD_TALK))
    }

    if report_status || report_time
      config.stderr.puts "Require protocol...\n#{separator = '-' * 61}"
      @attendees.first.listen(AgendaItem.new(STR_CMD_STATUS))
      config.stderr.puts "#{separator}\nThe duration of the meeting was #{time.to_hms(2)}"
    end
  end

  def reset(close = true)
    dictionaries.each(&:close) if close
    @dictionaries, @attendees = [], []
    @lexical_hash = Hash.new { |h, k| h[k] = LexicalHash.new(k, self) }
  end

  class Call < Lingo

    def initialize(args = [])
      super(args, StringIO.new, StringIO.new, StringIO.new)
    end

    def call
      invite

      if block_given?
        begin
          yield self
        ensure
          reset
        end
      else
        self
      end
    end

    def talk(str)
      config.stdin.reopen(str)

      start

      %w[stdout stderr].flat_map { |key|
        io = config.send(key).tap(&:rewind)
        io.readlines.each(&:chomp!).tap {
          io.truncate(0)
          io.rewind
        }
      }.tap { |res|
        if block_given?
          res.map!(&Proc.new)
        else
          res.sort!
          res.uniq!
        end
      }
    end

  end

end

require 'nuggets/util/pluggable'
Util::Pluggable.load_plugins_for(Lingo)
