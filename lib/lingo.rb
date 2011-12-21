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
require 'pathname'
require 'fileutils'

require_relative 'lingo/config'
require_relative 'lingo/meeting'
require_relative 'lingo/version'

class Lingo

  BASE = File.expand_path('../..', __FILE__)

  class << self

    def talk(*args)
      new(*args).talk
    end

    def call(cfg = File.join(BASE, 'lingo-call.cfg'), args = [])
      Call.new(['-c', cfg, *args]).tap { |lingo| lingo.talk('') }
    end

    def error(msg)
      abort(msg)
    end

  end

  attr_reader :config, :meeting, :dictionaries

  attr_accessor :report_status, :report_time

  def initialize(*args)
    @config, @meeting, @dictionaries = Config.new(*args), Meeting.new(self), []
  end

  def talk
    meeting.run(config['meeting/attendees'], config['status'], config['perfmon'])
  end

  def dictionary_config
    @dictionary_config ||= config['language/dictionary']
  end

  class Call < Lingo

    def initialize(args = [])
      super(args, StringIO.new, StringIO.new, StringIO.new)
    end

    def talk(str)
      config.stdin.reopen(str)

      Dir.chdir(BASE) { super() }

      res = %w[stdout stderr].map! { |key|
        config.send(key).
          tap { |io| io.rewind }.
          readlines.each(&:chomp!)
      }.flatten!

      if block_given?
        res.map!(&Proc.new)
      else
        res.sort!
        res.uniq!
      end

      res
    end

  end

end
