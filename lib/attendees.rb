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


=begin rdoc
== Attendee
Lingo ist als universelles Indexierungssystem entworfen worden. Seine Stärke liegt in der einfachen Konfigurierbarkeit für 
spezifische Aufgaben und in der schnelle Entwicklung weiterer Funktionen durch systematischen Kapselung der Komplexität auf
kleine Verarbeitungseinheiten. Die kleinste Verarbeitungseinheit wird Attendee genannt. Um ein gewünschtes Verarbeitungsergebnis
zu bekommen, werden die benötigten Attendees einfach in einer Reihe hinter einander geschaltet. Ein einfaches Beispiel hierfür ist
eine direkte Verbindung zwischen einem Textreader, einem Tokenizer und einem Textwriter. Alle drei Klassen sind von der Klasse
Attendee abgeleitet.

Der Textreader liest beispielsweise Zeilen aus einer Textdatei und leitet sie weiter an den Tokenizer. Der Tokenizer zerlegt eine
Textzeile in einzelne Wörter und gibt diese weiter an den Textwriter, der diese in eine (andere) Datei schreibt. Über vielfältige 
Konfigurationsmöglichkeiten kann das Verhalten der Attendees an die eigenen Bedürfnisse angepasst werden.

Die Verkettung einzelner Attendees findet über die Schnittstellen +listen+ und +talk+ statt. An +listen+ können beliebige Objekte 
zur Ver- und Bearbeitung übergeben werden. Nach der Verarbeitung werden sie mittels +talk+ an die verketteten Attendees weiter 
gegeben. Objekte der Klasse AgendaItem dienen dabei der Steuerung der Verarbeitung und sind nicht Bestandteil der normalen 
Verarbeitung. Beispiele für AgendaItems sind die Kommandos TALK (Aufforderung zum Start der Verarbeitung), WARN (zur Ausgabe von 
Warnungen eines Attendees) und EOL (End of Line, Ende einer Textzeile nach Zerlegung in einzelne Wörter). Eine vollständige 
Übersicht benutzer AgendaItems (oder auf Stream Commands) steht in lib/const.rb mit dem Prefix STR_CMD_.

Um die Entwicklung von neuen Attendees zu beschleunigen, wird durch die Vererbung sind bei wird die gesammte sind in der Regel nur 
drei abstrakte Methoden zu implementieren: +init+, +control+ und +process+. Die Methode +init+ wird bei der Instanziierung eines 
Objektes einmalig aufgerufen. Sie dient der Vorbereitung der Verarbeitung, z.B. durch das Öffnen und Bereitstellen von 
Wörterbüchern zur linguistischen Analyse. An die Methode +control+ werden alle eingehenden AgendaItems weitergeleitet. Dort erfolgt
die Verarbeitungssteuerung, also z.B. bei STR_CMD_FILE das Öffnen einer Datei und bei STR_CMD_EOF respektive das Schließen. Die 
echte Verarbeitung von Daten findet daher durch die Methode +process+ statt.

  
was macht attendee
- verkettung der attendees anhand von konfigurationsinformationen
- bereitstellung von globalen und spezifischen konfigurationsinformationen 
- behandlung von bestimmten übergreifenden Kommandos, z.B. STR_CMD_TALK, STR_CMD_STATUS, STR_CMD_WARN, STR_CMD_ERR
- separierung und routing von kommando bzw. datenobjekten

was macht die abgeleitet klasse
- verarbeitet und/oder transformiert datenobjekte
- wird gesteuert durch kommandos
- schreibt verarbeitungsstatistiken

=end

require_relative 'modules'
require_relative 'language'
require_relative 'const'
require_relative 'types'

class Attendee

  include Reportable

  @@library_config = nil
  @@report_status = false
  @@report_time = false

private

  def initialize(config)
    init_reportable

    begin
      @@library_config = Lingo::config['language/dictionary']
    rescue
      raise "Fehler in der .lang-Datei bei 'language/dictionary'"
    end if @@library_config.nil?
    
    #    Informationen für Teilnehmer vorbereiten
    @config = config
    @subscriber = Array.new
    
    #    Teilnehmer initialisieren
    init if self.class.method_defined?(:init)
    
    @attendee_can_control = self.class.method_defined?(:control)
    @attendee_can_process = self.class.method_defined?(:process)
    
    @skip_this_command = false
    @start_of_processing = nil
  end


public

  def add_subscriber( subscriber )
    @subscriber += subscriber
  end



  def listen(obj)
    
    unless obj.is_a?(AgendaItem)
      
      if @attendee_can_process
        inc(STA_NUM_OBJECTS)
        
        unless @@report_time
          process(obj) 
        else
          @start_of_processing = Time.new
          process(obj) 
          add(STA_TIM_OBJECTS, Time.new - @start_of_processing)
        end
      else
        forward(obj)
      end

    else

      case obj.cmd
      when STR_CMD_REPORT_STATUS
        @@report_status = true
        return
      when STR_CMD_REPORT_TIME
        @@report_time = true
        return
      end
      
      #    Neuen TOP verarbeiten
      if @attendee_can_control
        inc(STA_NUM_COMMANDS)

        unless @@report_time
          control(obj.cmd, obj.param)
        else
          @start_of_processing = Time.new
          control(obj.cmd, obj.param)
          add(STA_TIM_COMMANDS, Time.new - @start_of_processing)
        end
      end

      #    Spezialbehandlung für einige TOPs nach Verarbeitung
      case obj.cmd
      #    keine weitere Behandlung oder Weiterleitung
      when STR_CMD_TALK then nil
      #    Standardprotokollinformationen ausgeben
      when STR_CMD_STATUS
        if @@report_time
          puts 'Perf: %-15s => %7d commands in %s (%s/cmd),  %8d objects in %s (%s/obj)' % 
            [@config['name'],
            get(STA_NUM_COMMANDS), 
            seconds_to_str(get(STA_TIM_COMMANDS)),
            seconds_to_str((get(STA_NUM_COMMANDS)==0) ? 0.0 : get(STA_TIM_COMMANDS) / get(STA_NUM_COMMANDS).to_f),
            get(STA_NUM_OBJECTS), 
            seconds_to_str(get(STA_TIM_OBJECTS)), 
            seconds_to_str((get(STA_NUM_OBJECTS)==0) ? 0.0 : get(STA_TIM_OBJECTS) / get(STA_NUM_OBJECTS).to_f)]
        end
        if @@report_status
          printf "Attendee <%s> was connected from '%s' to '%s' reporting...\n", @config['name'], @config['in'], @config['out']
          report.to_a.sort.each { |info| puts " #{info[0]} = #{info[1]}" }
          puts
        end
        forward(obj.cmd, obj.param)
      else
        if @skip_this_command
          @skip_this_command = false
        else
          forward(obj.cmd, obj.param)
        end
      end
    end
  end


  def talk(obj)
    time_for_sub = Time.new if @@report_time
    @subscriber.each { |attendee| attendee.listen(obj) }
    @start_of_processing += (Time.new - time_for_sub) if @@report_time
  end


private
  
  #  ---------------------------------------------------
  #    Create intelligent output of performance times
  #    measured with to command line option -p
  #  ---------------------------------------------------

  def seconds_to_str(float)
    if float < 0.001
      "%9.3f µs" % [float * 1000000.0]
    elsif float < 1.0
      "%9.3f ms" % [float * 1000.0]
    elsif float < 60.0
      "%9.3f s " % [float]
    elsif float < 3600.0
      "%9.3f m " % [float / 60.0]
    else
      "%9.3f h " % [float / 3600.0]
    end
  end

  
  def deleteCmd
    @skip_this_command = true
  end
  

  def forward(obj, param=nil)
    if param.nil?
      #    Information weiterreichen
      talk(obj)
    else
      #    TOP weiterreichen (wenn keine Warnung oder Fehler)
      case obj
        when STR_CMD_WARN  then printf "+%s\n|   %s: %s\n+%s\n", '-'*60, @config['name'], param, '-'*60
        when STR_CMD_ERR  then printf "%s\n=   %s: %s\n%s\n", '='*61, @config['name'], param, '='*61;  exit( 1 )
        else
          talk(AgendaItem.new(obj, param))
      end
    end
  end


  #  ---------------------------------------------------
  #    Konfigurationshilfsmethoden
  #  ---------------------------------------------------
  def has_key?(key)
    !@config.nil? && @config.has_key?(key)
  end

  
  def get_key(key, default=nil)
    forward(STR_CMD_ERR, "Attribut #{key} nicht gesetzt") if default.nil? && !has_key?(key)
    @config.fetch(key, default)
  end


  def get_array(key, default=nil)
    get_key(key, default).split(STRING_SEPERATOR_PATTERN)
  end


  #  ---------------------------------------------------
  #    Abstrakte Methoden
  #
  #    init
  #    control(cmd, param)
  #    process(obj)
  #  ---------------------------------------------------
end


#==============================================================================
#    BufferedAttendee
#==============================================================================

class BufferedAttendee < Attendee

  BufferInsert = Struct.new(:position, :object)

  def initialize(config)
    #  In den Buffer werden alle Objekte geschrieben, bis process_buffer? == true ist
    @buffer = []

    #  deferred_inserts beeinflussen nicht die Buffer-Größe, sondern werden an einer
    #  bestimmten Stelle in den Datenstrom eingefügt
    @deferred_inserts = []

    super
  end

  protected

  def process(obj)
    @buffer.push(obj)
    process_buffer if process_buffer?
  end

  private

  def forward_buffer
    #  Aufgeschobene Einfügungen in Buffer kopieren
    @deferred_inserts.sort_by { |ins| ins.position }.each { |ins|
      @buffer.insert(ins.position, ins.object)
    }
    @deferred_inserts.clear

    #  Buffer weiterleiten
    @buffer.each { |obj| forward(obj) }
    @buffer.clear
  end

  def process_buffer?
    true
  end

  def process_buffer
    #  to be defined by child class
  end

  def deferred_insert(pos, obj)
    @deferred_inserts << BufferInsert.new(pos, obj)
  end

end
