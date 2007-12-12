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


=begin rdoc
== Synonymer
Der Synonymer untersucht die von anderen Attendees ermittelten Grundformen eines Wortes
und sucht in den angegebenen Wörterbüchern nach Relationen zu anderen Grundformen.
Gefundene Relationen erweitern die Liste des Word-Objektes und werden zur späteren 
Identifizierung mit der Wortklasse 'y' gekennzeichnet.

=== Mögliche Verlinkung
Erwartet:: Daten vom Typ *Word* z.B. von Wordsearcher, Decomposer, Ocr_variator, Multiworder
Erzeugt:: Daten vom Typ *Word* (ggf. um Relationen ergänzt) z.B. für Decomposer, Ocr_variator, Multiworder, Sequencer, Noneword_filter, Vector_filter

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee
<b>out</b>:: siehe allgemeine Beschreibung des Attendee
<b>source</b>:: siehe allgemeine Beschreibung des Dictionary
<b><i>mode</i></b>:: (Standard: all) siehe allgemeine Beschreibung des Dictionary
<b><i>skip</i></b>:: (Standard: WA_UNKNOWN [siehe strings.rb]) Veranlasst den Synonymer 
                     Wörter mit diesem Attribut zu überspringen.

=== Beispiele
Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader:   { out: lines, files: '$(files)' }
      - tokenizer:    { in: lines, out: token }
      - abbreviator:  { in: token, out: abbrev, source: 'sys-abk' }
      - wordsearcher: { in: abbrev, out: words, source: 'sys-dic' }
      - synonymer:    { in: words, out: synos, source: 'sys-syn' }
      - debugger:     { in: words, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  out> *FILE('test.txt')
  out> <Dies = [(dies/w), (das/y), (dies/y)]>
  out> <ist = [(sein/v), ((sich) befinden/y), (dasein/y), (existenz/y), (sein/y), (vorhandensein/y)]>
  out> <ggf. = [(gegebenenfalls/w), (bei bedarf/y), (gegebenenfalls/y), (ggf./y), (notfalls/y)]>
  out> <eine = [(einen/v), (ein/w)]>
  out> <Abk³rzung = [(abk³rzung/s), (abbreviation/y), (abbreviatur/y), (abk³rzung/y), (akronym/y), (kurzbezeichnung/y)]>
  out> :./PUNC:
  out> *EOL('test.txt')
  out> *EOF('test.txt')
=end


class Synonymer < Attendee

protected

  def init
    #  Wörterbuch bereitstellen
    src = get_array('source')
    mod = get_key('mode', 'all')
    @dic = Dictionary.new({'source'=>src, 'mode'=>mod}, @@library_config)

    @skip = get_array('skip', WA_UNKNOWN).collect {|s| s.upcase }
  end


  def control(cmd, par)
    @dic.report.each_pair { |k, v| set( k, v ) } if cmd == STR_CMD_STATUS
  end


  def process(obj)
    if obj.is_a?(Word) && @skip.index(obj.attr).nil?
      inc('Anzahl gesuchter Wörter')

      #    finde die Synonyme für alle Lexicals des Wortes

      #  alle Lexicals des Wortes
      lexis = obj.lexicals
      #  alle Lexical-Wortformen, um gleichlautende Synonyme zu filtern
      forms = lexis.collect { |lex| lex.form }
      #  alle gefundenen Synonyme
      synos = []

      lexis.each do |lex|
        #  Synonyme für Teile eines Kompositum ausschließen
        next if obj.attr==WA_KOMPOSITUM && lex.attr!=LA_KOMPOSITUM
        #  Synonyme für Synonyme ausschließen
        next if lex.attr==LA_SYNONYM
        
        @dic.select(lex.form).each do |syn| 
          #  Gleichlautende Synonyme ausschließen
          next if syn =~ /^\*(\d+)/
          next unless forms.index(syn.form).nil?
          synos << syn
        end
      end
      obj.lexicals += synos.sort.uniqual

      inc('Anzahl erweiteter Wörter') if synos.size>0
      add('Anzahl gefundener Synonyme', synos.size)
    end
    forward(obj)
  end

end
