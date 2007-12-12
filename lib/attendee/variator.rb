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
== Variator
Der Variator ermöglicht bei nicht erkannten Wörtern den listenbasierten 
Austausch einzelner Wortteile einchließlich erneuter Wörterbuchsuche zur 
Verbesserung der Worterkennungsquote.

Ursprünglich wurde der Variator entwickelt, um die mangelnde Qualität bei der
OCR-Erkennung altdeutscher 's'-Konsonanten zu optimieren. Er kann ebenso bei
alternativen Umlautschreibweisen z.B. zur Wandlung von 'Koeln' in 'Köln' dienen.

=== Mögliche Verlinkung
Erwartet:: Daten vom Typ *Word* (andere werden einfach durchgereicht) z.B. von Wordsearcher
Erzeugt:: Daten vom Typ *Word* zur Weiterleitung z.B. an Synonymer, Decomposer, Multiworder, Sequencer, Noneword_filter oder Vector_filter

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee
<b>out</b>:: siehe allgemeine Beschreibung des Attendee
<b>source</b>:: siehe allgemeine Beschreibung des Dictionary
<b><i>mode</i></b>:: (Standard: all) siehe allgemeine Beschreibung des Dictionary
<b><i>^check</i></b>:: (Standard: WA_UNKNOWN) Gebrenzt die zu variierenden Worttypen
<b><i>marker</i></b>:: (Standard: '*') Kennzeichnung durch Variation erkannter Wörter
<b><i>max-var</i></b>:: (Standard: '10000') Begrenzung der maximal zu prüfenden Permutationen bei der vollständigen Kombination aller auf ein Wort anzuwendenen aufgelisteten Wortteile.

=== Beispiele
Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader:   { out: lines, files: '$(files)' }
      - tokenizer:    { in: lines, out: token }
      - wordsearcher: { in: abbrev, out: words, source: 'sys-dic' }
      - variator:     { in: words, out: varios, source: 'sys-dic' }
      - debugger:     { in: varios, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  out> *FILE('test.txt')
  out> <*Dies = [(dies/w)]>
  out> <*ist = [(ist/t)]>
  out> <ein = [(ein/t)]>
  out> <*Tisch = [(tisch/s)]>
  out> :./PUNC:
  out> *EOL('test.txt')
  out> *EOF('test.txt')
=end


class Variator < Attendee

protected

  def init
    #  Parameter verarbeiten
    @marker  = get_key('marker', '*')
    @max_var = get_key('max-var', '10000').to_i
    filter = get_array('check', WA_UNKNOWN)
    
    src = get_array('source')
    mod = get_key('mode', 'all')

    #  Daten verarbeiten
    @var_strings = get_key('variations')
    forward(STR_CMD_ERR, 'Ocr-variator: Konfiguration <ocr-variator> ist leer') if @var_strings.size==0

    #  Initialisierungen
    @check = Hash.new(false)
    filter.each { |s| @check[s.upcase] = true }
  
    #  Wörterbuchzugriff
    @dic = Dictionary.new({'source'=>src, 'mode'=>mod}, @@library_config)
    @gra = Grammar.new({'source'=>src, 'mode'=>mod}, @@library_config)
    
    #  Optimierungen
    if @max_var == 0
      forward( STR_CMD_WARN, 'Ocr-variator: max-var ist 0, setze es auf 10.000' )
      @max_var = 10000
    end
  end


  def control(cmd, par)
    #  Status wird abgefragt
    if cmd == STR_CMD_STATUS
      #  Eigenen Status um Status von Dictionary und Grammer erweitern
      @dic.report.each_pair { | k, v | set( k, v ) }
      @gra.report.each_pair { | k, v | set( k, v ) }
    end
  end


  def process(obj)
    #  Zu prüfende Wörter filtern
    if obj.is_a?(Word) && @check[obj.attr]
      #  Statistik für Report
      inc('Anzahl gesuchter Wörter')

      #  Erzeuge Variationen einer Wortform
      variations = [obj.form]
      @var_strings.each do |switch|
        from, to = switch
        variations = variate(variations, from, to)
      end

      #  Prüfe Variation auf bekanntes Wort
      variations[0...@max_var].each do |var|
        #  Variiertes Wort im Wörterbuch suchen
        word = @dic.find_word(var)
        word = @gra.find_compositum(var) if word.attr == WA_UNKNOWN
        next if word.attr == WA_UNKNOWN

        #  Das erste erkannte Wort beendet die Suche
        inc('Anzahl gefundener Wörter')
        word.form = @marker + var
        forward(word)
        return
      end
    end
    
    forward(obj)
  end


private

  #  Variiere die Bestandteile eines Arrays gemäß den Austauschvorgaben.
  #
  #  variate( 'Tiieh', 'ieh', 'sch' ) => ['Tiieh', 'Tisch']
  def variate(variation_list, from, to)
    #  neue Varianten sammeln
    add_variations = []
    from_re = Regexp.new(from)
    
    #  alle Wörter in der variation_list permutieren
    variation_list.each do |wordform|

      #  Wortform in Teile zerlegen und anschließend Dimension feststellen
      wordpart = " #{wordform} ".split( from_re )
      n = wordpart.size - 1

      #  Austauschketten in Matrix hinterlegen
      change = [from, to]

      #  Austauschketten auf alle Teile anwenden
      (1..(2**n-1)).each do |i|
        variation = wordpart[0]
        #  i[x] = Wert des x.ten Bit von Integer i
        (1..n).each { |j| variation += change[i[j-1]] + wordpart[j]  }
        
        add_variations << variation.strip
      end
    end
    
    variation_list + add_variations
  end
  
end
