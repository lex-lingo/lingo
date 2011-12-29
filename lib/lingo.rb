# encoding: utf-8

#--
# LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
# Mehrworterkennung und Relationierung.
#
# Copyright (C) 2005-2007 John Vorhauer
# Copyright (C) 2007-2011 John Vorhauer, Jens Wille
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
require_relative 'lingo/attendee/helper'
require_relative 'lingo/version'

class Lingo

  BASE = File.expand_path('../..', __FILE__)

  class << self

    def talk(*args)
      new(*args).talk
    end

    def call(cfg = File.join(BASE, 'lingo-call.cfg'), args = [], &block)
      Call.new(['-c', cfg, *args]).call(&block)
    end

    def error(msg)
      abort(msg)
    end

  end

  attr_reader :config, :dictionaries, :report_status, :report_time

  def initialize(*args)
    @config = Config.new(*args)
    reset(false)
  end

  def dictionary_config
    @dictionary_config ||= config['language/dictionary']
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
