#! /usr/bin/ruby

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
#  welcomeATlex-lingoDOTde near 50∞55'N+6∞55'E.
#
#  Lex Lingo rules from here on



$KCODE = 'n'

#require 'English'
require 'lib/config'
require 'lib/meeting'


class Lingo

private

	@@config = nil
	
	def initialize(prog=$0, cmdline=$*)

		$stdin.sync = true
		$stdout.sync = true
		
		#	Konfiguration bereitstellen
		@@config = LingoConfig.new(prog, cmdline)
		
		#	Protokoll-Stufe ermitteln
		begin
			@protocol_level = (Lingo::config['meeting/protocol']=="false" ? 1 : 2)
			attendee_config = Lingo::config['meeting/attendees']
		rescue
			raise "Fehler in der .cfg-Datei bei 'meeting/protocol' oder 'meeting/attendees'"
		end

		
		
#		extend_attendee_config
#		p @@config['meeting']['attendees']

		#	Meeting einberufen
		@@meeting = Meeting.new
	end


	def extend_attendee_config
		#	Attendee-Namen setzen
		@@config['meeting/attendees'].each do |att_cfg|
			name, values = att_cfg.to_a[0]
			values['name'] = name.capitalize
			
			#	Attendee-Daten erg√§nzen
			data = @@config['language']['attendees'][name.downcase]
			values.update( @@config['language']['attendees'][name.downcase] ) unless data.nil?
		end
	end

	
public
	
	def Lingo.config
		Lingo.new( 'lingo.rb', [] ) if @@config.nil?
		@@config
	end

	
	def Lingo.meeting
		@@meeting
	end
	
	def Lingo.error(txt)
		puts
		puts txt
		puts
		exit
	end

	def talk
		attendees = @@config['meeting/attendees']
		@@meeting.invite(attendees)
		
		protocol = @@config['meeting/protocol']
		protocol_level = ((protocol.nil? || eval( protocol ) == false) ? 1 : 2)
		@@meeting.start(protocol_level)
	end
end

if $0 == __FILE__

	Lingo.new.talk

end
