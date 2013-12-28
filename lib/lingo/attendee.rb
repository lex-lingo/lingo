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

require 'nuggets/string/evaluate'

class Lingo

  # Lingo ist als universelles Indexierungssystem entworfen worden. Seine Stärke liegt in der einfachen Konfigurierbarkeit für
  # spezifische Aufgaben und in der schnelle Entwicklung weiterer Funktionen durch systematischen Kapselung der Komplexität auf
  # kleine Verarbeitungseinheiten. Die kleinste Verarbeitungseinheit wird Attendee genannt. Um ein gewünschtes Verarbeitungsergebnis
  # zu bekommen, werden die benötigten Attendees einfach in einer Reihe hinter einander geschaltet. Ein einfaches Beispiel hierfür ist
  # eine direkte Verbindung zwischen einem Textreader, einem Tokenizer und einem Textwriter. Alle drei Klassen sind von der Klasse
  # Attendee abgeleitet.
  #
  # Der Textreader liest beispielsweise Zeilen aus einer Textdatei und leitet sie weiter an den Tokenizer. Der Tokenizer zerlegt eine
  # Textzeile in einzelne Wörter und gibt diese weiter an den Textwriter, der diese in eine (andere) Datei schreibt. Über vielfältige
  # Konfigurationsmöglichkeiten kann das Verhalten der Attendees an die eigenen Bedürfnisse angepasst werden.
  #
  # Die Verkettung einzelner Attendees findet über die Schnittstellen +listen+ und +talk+ statt. An +listen+ können beliebige Objekte
  # zur Ver- und Bearbeitung übergeben werden. Nach der Verarbeitung werden sie mittels +talk+ an die verketteten Attendees weiter
  # gegeben. Objekte der Klasse AgendaItem dienen dabei der Steuerung der Verarbeitung und sind nicht Bestandteil der normalen
  # Verarbeitung. Beispiele für AgendaItems sind die Kommandos TALK (Aufforderung zum Start der Verarbeitung), WARN (zur Ausgabe von
  # Warnungen eines Attendees) und EOL (End of Line, Ende einer Textzeile nach Zerlegung in einzelne Wörter). Eine vollständige
  # Übersicht benutzer AgendaItems (oder auf Stream Commands) steht in lib/const.rb mit dem Prefix STR_CMD_.
  #
  # Um die Entwicklung von neuen Attendees zu beschleunigen, wird durch die Vererbung sind bei wird die gesammte sind in der Regel nur
  # drei abstrakte Methoden zu implementieren: +init+, +control+ und +process+. Die Methode +init+ wird bei der Instanziierung eines
  # Objektes einmalig aufgerufen. Sie dient der Vorbereitung der Verarbeitung, z.B. durch das Öffnen und Bereitstellen von
  # Wörterbüchern zur linguistischen Analyse. An die Methode +control+ werden alle eingehenden AgendaItems weitergeleitet. Dort erfolgt
  # die Verarbeitungssteuerung, also z.B. bei STR_CMD_FILE das Öffnen einer Datei und bei STR_CMD_EOF respektive das Schließen. Die
  # echte Verarbeitung von Daten findet daher durch die Methode +process+ statt.
  #
  # was macht attendee
  # - verkettung der attendees anhand von konfigurationsinformationen
  # - bereitstellung von globalen und spezifischen konfigurationsinformationen
  # - behandlung von bestimmten übergreifenden Kommandos, z.B. STR_CMD_TALK
  # - separierung und routing von kommando bzw. datenobjekten
  #
  # was macht die abgeleitet klasse
  # - verarbeitet und/oder transformiert datenobjekte
  # - wird gesteuert durch kommandos
  # - schreibt verarbeitungsstatistiken

  class Attendee

    include Language

    STR_CMD_TALK   = 'TALK'
    STR_CMD_LIR    = 'LIR-FORMAT'
    STR_CMD_FILE   = 'FILE'
    STR_CMD_EOL    = 'EOL'
    STR_CMD_RECORD = 'RECORD'
    STR_CMD_EOF    = 'EOF'

    DEFAULT_SKIP = [TA_PUNCTUATION, TA_OTHER].join(',')

    def initialize(config, lingo)
      @lingo, @config, @subscriber = lingo, config, []

      # Make sure config exists
      lingo.dictionary_config

      init if self.class.method_defined?(:init)

      @can_control = self.class.method_defined?(:control)
      @can_process = self.class.method_defined?(:process)

      @skip_command = false
    end

    attr_reader :lingo

    def add_subscriber(subscriber)
      @subscriber.concat(subscriber)
    end

    def listen(obj)
      if obj.is_a?(AgendaItem)
        args = obj.to_a
        control(*args) if @can_control
        forward(*args) unless obj.cmd == STR_CMD_TALK || skip_command!
      else
        @can_process ? process(obj) : forward(obj)
      end
    end

    def talk(obj)
      @subscriber.each { |attendee| attendee.listen(obj) }
    end

    private

    def find_word(f, d = @dic, g = @gra)
      w = d.find_word(f)
      g && (block_given? ? !yield(w) : w.unknown?) ? g.find_compound(f) : w
    end

    def skip_command
      @skip_command = true
    end

    def skip_command!
      @skip_command.tap { @skip_command &&= false }
    end

    def forward(obj, param = nil)
      talk(param ? AgendaItem.new(obj, param) : obj)
    end

    def flush(buffer)
      buffer.each { |i| forward(i) }.clear
    end

    def has_key?(key)
      @config && @config.key?(key)
    end

    def get_key(key, default = nodefault = true)
      raise MissingConfigError.new(key) if nodefault && !has_key?(key)
      @config.fetch(key, default)
    end

    def get_array(key, default = nil, method = nil)
      ary = get_key(key, default).split(SEP_RE)
      ary.map!(&method) if method
      ary
    end

    def get_re(key, default = nil, standard = nil)
      if value = get_key(key, default)
        value == true ? standard : Regexp.new(value)
      end
    end

    def dictionary(src, mod)
      Language::Dictionary.new({ 'source' => src, 'mode' => mod }, lingo)
    end

    def grammar(src, mod)
      Language::Grammar.new({ 'source' => src, 'mode' => mod }, lingo)
    end

    def set_dic
      @dic = dictionary(get_array('source'), get_key('mode', 'all'))
    end

    def set_gra
      @gra = grammar(get_array('source'), get_key('mode', 'all'))
    end

    def warn(*msg)
      lingo.warn(*msg)
    end

    def require_lib(lib)
      require lib
    rescue LoadError => err
      raise LibraryLoadError.new(self.class, lib, err)
    end

  end

end

require_relative 'buffered_attendee'

require_relative 'attendee/abbreviator'
require_relative 'attendee/debugger'
require_relative 'attendee/decomposer'
require_relative 'attendee/dehyphenizer'
require_relative 'attendee/multi_worder'
require_relative 'attendee/noneword_filter'
require_relative 'attendee/object_filter'
require_relative 'attendee/variator'
require_relative 'attendee/sequencer'
require_relative 'attendee/stemmer'
require_relative 'attendee/synonymer'
require_relative 'attendee/text_reader'
require_relative 'attendee/text_writer'
require_relative 'attendee/formatter'
require_relative 'attendee/tokenizer'
require_relative 'attendee/vector_filter'
require_relative 'attendee/word_searcher'
