#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung, 
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005  John Vorhauer
#
#  This program is free software; you can redistribute it and/or modify it under 
#  the terms of the GNU General Public License as published by the Free Software 
#  Foundation;  either version 2 of the License, or  (at your option)  any later
#  version.
#
#  This program is distributed  in the hope  that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
#  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#  You should have received a copy of the  GNU General Public License along with 
#  this program; if not, write to the Free Software Foundation, Inc., 
#  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
#  For more information visit http://www.lex-lingo.de or contact me at
#  welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
#  Lex Lingo rules from here on


require 'lib/attendees'

require 'lib/attendee/abbreviator'
require 'lib/attendee/debugger'
require 'lib/attendee/decomposer'
require 'lib/attendee/dehyphenizer'
require 'lib/attendee/multiworder'
require 'lib/attendee/noneword_filter'
require 'lib/attendee/objectfilter'
require 'lib/attendee/variator'
require 'lib/attendee/sequencer'
require 'lib/attendee/synonymer'
require 'lib/attendee/textreader'
require 'lib/attendee/textwriter'
require 'lib/attendee/tokenizer'
require 'lib/attendee/vector_filter'
require 'lib/attendee/wordsearcher'
require 'lib/attendee/helper'



class Meeting

private

	#	Meeting initialisieren
	def initialize
		@attendees = Array.new
	end


public

	#	Einladen aller Teilnehmer
	def invite( invitation_list )

		#	Daten für Verlinkung der Teilnehmer vorbereiten	
		supplier = Hash.new( [] )
		subscriber = Hash.new( [] )

		#	Teilnehmer einzeln einladen		
		invitation_list.each do |cfg|
			#	att = {'attendee' => {'name'=>'Attendee', 'in'=>'nase', 'out'=>'ohr', 'param'=>'hase'}}
			config = cfg.values[ 0 ]
			config['name'] = cfg.keys[ 0 ].capitalize

			#	Link-Parameter standardisieren
			[ 'in', 'out' ].each do |key|
				config[ key ] ||= ''
				config[ key ].downcase!
			end

			#	Attendee-Daten ergänzen
			data = Lingo.config["language/attendees/#{config['name'].downcase}"]
			config.update( data ) unless data.nil?

			#	Teilnehmer-Objekt erzeugen
			attendee = eval( config[ 'name' ] + ".new(config)" )
			exit if attendee.nil?
			@attendees << attendee

			#	Supplier und Subscriber merken			
			config[ 'in' ].split( STRING_SEPERATOR_PATTERN ).each do |interest|
				subscriber[ interest ] += [ attendee ]
			end
			config[ 'out' ].split( STRING_SEPERATOR_PATTERN ).each do |theme|
				supplier[ theme ] += [ attendee ]
			end
		end

		#	Teilnehmer verlinken
		supplier.each do |supp|
			channel, attendees = supp
			attendees.each do |att|
				att.add_subscriber( subscriber[ channel ] )
			end
		end
	end


	#		protocol = 0		Keinerlei Ausgaben
	#		protocol = 1		Normales Protokoll
	#		protocol = 2		Protokoll mit Statistik
	def start( protocol )
		#	Besprechung starten
		start_time = Time.new
		@attendees.first.listen( AgendaItem.new( STR_CMD_TALK ) )

		#		Besprechung beenden
		end_time = Time.new
		if protocol == 2
			puts "Erbitte Sitzungsprotokoll..."
			puts '-'*61
			@attendees.first.listen( AgendaItem.new( STR_CMD_STATUS ) )
		end

		#		Dauer der Sitzung
		if protocol > 0
			duration, units = (end_time-start_time), 'sec.'
			duration, units = (duration/60.0), 'min.' if duration > 60
			duration, units = (duration/60.0), 'std.' if duration > 60
	
			printf "%s\nDie Dauer der Sitzung war %5.2f %s\n", '-'*61, duration, units
		end
	end


	def reset
		@attendees = Array.new
	end

end

