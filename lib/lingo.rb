# encoding: utf-8

#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005-2007 John Vorhauer
#  Copyright (C) 2007-2010 John Vorhauer, Jens Wille
#
#  This program is free software; you can redistribute it and/or modify it under
#  the terms of the GNU Affero General Public License as published by the Free
#  Software Foundation; either version 3 of the License, or (at your option)
#  any later version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
#  details.
#
#  You should have received a copy of the GNU Affero General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
#  For more information visit http://www.lex-lingo.de or contact me at
#  welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
#  Lex Lingo rules from here on

require 'pathname'
require 'fileutils'

require_relative 'config'
require_relative 'meeting'
require_relative 'lingo/version'

class Lingo

  BASE = File.expand_path('../..', __FILE__)

  class << self

    def talk
      new.talk
    end

    def call(cfg = 'lingo-call.cfg', args = [])
      new(['-c', cfg, *args]).tap { |lingo| lingo.talk_to_me('') }
    end

    def error(msg)
      abort(msg)
    end

  end

  attr_reader :config, :meeting, :dictionaries

  attr_accessor :report_status, :report_time

  def initialize(*args)
    $stdin.sync = $stdout.sync = true
    @config, @meeting, @dictionaries = LingoConfig.new(*args), Meeting.new(self), []
  end

  def talk
    meeting.run(config['meeting/attendees'], config['status'], config['perfmon'])
  end

  def talk_to_me(str)
    begin
      stdin,  $stdin  = $stdin,        StringIO.new(str)
      stdout, $stdout = $stdout, out = StringIO.new

      Dir.chdir(BASE) { talk }
    ensure
      $stdin, $stdout = stdin, stdout
    end

    res = out.string.split($/)

    if block_given?
      res.map!(&Proc.new)
    else
      res.sort!
      res.uniq!
    end

    res
  end

  def dictionary_config
    @dictionary_config ||= config['language/dictionary']
  end

end
