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

class Lingo

  BASE = File.expand_path('../..', __FILE__)

  @@config = nil

  class << self

    def config
      new unless @@config
      @@config
    end

    def call(cfg = 'lingo-call.cfg', args = [])
      lingo = new('-c', cfg, *args)
      lingo.talk_to_me('')  # just to build the dicts
      lingo
    end

    def meeting
      @@meeting
    end

    def error(msg)
      abort(msg)
    end

  end

  def initialize(*args)
    $stdin.sync = $stdout.sync = true
    @@config, @@meeting = LingoConfig.new(*args), Meeting.new
  end

  def talk
    @@meeting.invite(@@config['meeting/attendees'])

    protocol  = 0
    protocol += 1 if @@config['cmdline/status']
    protocol += 2 if @@config['cmdline/perfmon']

    @@meeting.start(protocol)

    @@meeting.cleanup
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

end
