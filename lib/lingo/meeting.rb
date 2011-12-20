# encoding: utf-8

#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005-2007 John Vorhauer
#  Copyright (C) 2007-2011 John Vorhauer, Jens Wille
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

require 'benchmark'
require 'nuggets/numeric/duration'

require_relative 'attendees'

require_relative 'attendee/abbreviator'
require_relative 'attendee/debugger'
require_relative 'attendee/decomposer'
require_relative 'attendee/dehyphenizer'
require_relative 'attendee/multiworder'
require_relative 'attendee/noneword_filter'
require_relative 'attendee/objectfilter'
require_relative 'attendee/variator'
require_relative 'attendee/sequencer'
require_relative 'attendee/synonymer'
require_relative 'attendee/textreader'
require_relative 'attendee/textwriter'
require_relative 'attendee/tokenizer'
require_relative 'attendee/vector_filter'
require_relative 'attendee/wordsearcher'
require_relative 'attendee/helper'

class Lingo

class Meeting

  def initialize(lingo)
    @lingo = lingo
    reset
  end

  def run(attendees, *reports)
    invite(attendees)
    start(*reports)
  ensure
    cleanup
  end

  def invite(invitation_list)
    #  Daten für Verlinkung der Teilnehmer vorbereiten
    supplier   = Hash.new { |h, k| h[k] = [] }
    subscriber = Hash.new { |h, k| h[k] = [] }

    # Daten für automatische Verlinkung vorbereiten
    last_link_out, auto_link_number = '', 0

    #  Teilnehmer einzeln einladen
    invitation_list.each { |cfg|
      #  att = {'attendee' => {'name'=>'Attendee', 'in'=>'nase', 'out'=>'ohr', 'param'=>'hase'}}
      config = cfg.values[0]
      config['name'] = cfg.keys[0].capitalize

      #  Link-Parameter standardisieren
      %w[in out].each { |key|
        config[key] ||= ''
        config[key].downcase!
      }

      # Automatisch verlinken
      config['in'] = last_link_out if config['in'].empty?
      config['out'] = "auto_link_out_#{auto_link_number += 1}" if config['out'].empty?
      last_link_out = config['out']

      #  Attendee-Daten ergänzen
      data = @lingo.config["language/attendees/#{config['name'].downcase}"]
      config.update(data) if data

      #  Teilnehmer-Objekt erzeugen
      attendee = Attendee.const_get(config['name']).new(config, @lingo) or exit
      @attendees << attendee

      #  Supplier und Subscriber merken
      config['in'].split(STRING_SEPERATOR_PATTERN).each { |interest|
        subscriber[interest] << attendee
      }
      config['out'].split(STRING_SEPERATOR_PATTERN).each { |theme|
        supplier[theme] << attendee
      }
    }

    #  Teilnehmer verlinken
    supplier.each { |channel, attendees| attendees.each { |att|
      att.add_subscriber(subscriber[channel])
    } }
  end

  def start(report_status = false, report_time = false)
    @lingo.report_status = report_status
    @lingo.report_time   = report_time

    time = Benchmark.realtime {
      @attendees.first.listen(AgendaItem.new(STR_CMD_TALK))
    }

    if report_status || report_time
      $stderr.puts "Require protocol...\n#{separator = '-' * 61}"
      @attendees.first.listen(AgendaItem.new(STR_CMD_STATUS))
      $stderr.puts "#{separator}\nThe duration of the meeting was #{time.to_hms(2)}"
    end
  end

  def reset
    @attendees = []
  end

  private

  def cleanup
    @lingo.dictionaries.each(&:close)
  end

end

end
