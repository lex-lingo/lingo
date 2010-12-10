# encoding: utf-8

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

class WordSequence

  attr_reader :classes, :format, :string

  def initialize(wordclasses, format)
    @string  = wordclasses.downcase
    @classes = @string.split(//)
    @format  = format
  end

  def scan(sequence)
    pos = 0

    while pos = sequence.index(string, pos)
      yield pos, format.dup, classes
      pos += 1
    end
  end

end


=begin rdoc
== Sequencer
Der Sequencer ist von seiner Funktion her ähnlich dem Multiworder. Der Multiworder 
nutzt zur Erkennung von Mehrwortgruppen spezielle Wörterbücher, der Sequencer hingegen
definierte Folgen von Wortklassen. Mit dem Sequencer können Indexterme generiert werden,
die sich über mehrere Wörter erstrecken. 
Die Textfolge "automatische Indexierung und geniale Indexierung"
wird bisher in die Indexterme "automatisch", "Indexierung" und "genial" zerlegt.
Über die Konfiguration kann der Sequencer Mehrwortgruppen identifizieren, die 
z.B. aus einem Adjektiv und einem Substantiv bestehen. Mit der o.g. Textfolge würde
dann auch "Indexierung, automatisch" und "Indexierung, genial" als Indexterm erzeugt
werden. Welche Wortklassenfolgen erkannt werden sollen und wie die Ausgabe aussehen 
soll, wird dem Sequencer über seine Konfiguration mitgeteilt.

=== Mögliche Verlinkung
Erwartet:: Daten vom Typ *Word* z.B. von Wordsearcher, Decomposer, Ocr_variator, Multiworder
Erzeugt:: Daten vom Typ *Word* (mit Attribut WA_SEQUENCE). Je erkannter Mehrwortgruppe wird ein zusätzliches Word-Objekt in den Datenstrom eingefügt. Z.B. für Ocr_variator, Sequencer, Noneword_filter, Vector_filter

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee
<b>out</b>:: siehe allgemeine Beschreibung des Attendee
<b><i>stopper</i></b>:: (Standard: TA_PUNCTUATION, TA_OTHER) Gibt die Begrenzungen an, zwischen 
                        denen der Sequencer suchen soll, i.d.R. Satzzeichen und Sonderzeichen, 
                        weil sie kaum in einer Mehrwortgruppen vorkommen.

=== Konfiguration
Der Sequencer benötigt zur Identifikation von Mehrwortgruppen Regeln, nach denen er 
arbeiten soll. Die benötigten Regeln werden nicht als Parameter, sondern in der 
Sprachkonfiguration hinterlegt, die sich standardmäßig in der Datei
<tt>de.lang</tt> befindet (YAML-Format).
  language:
    attendees:
      sequencer:
        sequences: [ [AS, "2, 1"], [AK, "2, 1"] ]
Hiermit werden dem Sequencer zwei Regeln mitgeteilt: Er soll Adjektiv-Substantiv- (AS) und 
Adjektiv-Kompositum-Folgen (AK) erkennen. Zusätzlich ist angegeben, in welchem Format die
dadurch ermittelte Wortfolge ausgegeben werden soll. In diesem Beispiel also zuerst das 
Substantiv und durch Komma getrennt das Adjektiv.

=== Beispiele
Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader:   { out: lines, files: '$(files)' }
      - tokenizer:    { in: lines, out: token }
      - wordsearcher: { in: token, out: words, source: 'sys-dic' }
      - sequencer:    { in: words, out: seque }
      - debugger:     { in: seque, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  out> *FILE('test.txt')
  out> <Lingo|?>
  out> <kann = [(koennen/v)]>
  out> <indexierung, automatisch|SEQ = [(indexierung, automatisch/q)]>
  out> <automatische = [(automatisch/a)]>
  out> <Indexierung = [(indexierung/s)]>
  out> <und = [(und/w)]>
  out> <indexierung, genial|SEQ = [(indexierung, genial/q)]>
  out> <geniale = [(genial/a), (genialisch/a)]>
  out> <Indexierung = [(indexierung/s)]>
  out> :./PUNC:
  out> *EOL('test.txt')
  out> *EOF('test.txt')
=end



class Attendee::Sequencer < BufferedAttendee

protected

  def init
    #  Parameter verwerten
    @stopper = get_array('stopper', TA_PUNCTUATION+','+TA_OTHER).collect {|s| s.upcase }
    @seq_strings = get_key('sequences')
    @seq_strings.collect! { |e| WordSequence.new(e[0], e[1]) }
    forward(STR_CMD_ERR, 'Konfiguration ist leer') if @seq_strings.size==0
  end


  def control(cmd, par)
    #  Jedes Control-Object ist auch Auslöser der Verarbeitung
    process_buffer
  end


  def process_buffer?
    @buffer[-1].kind_of?(StringA) && @stopper.include?(@buffer[-1].attr.upcase)
  end


  def process_buffer
    return if @buffer.empty?

    sequences(@buffer.map { |obj|
      obj.is_a?(Word) && !obj.unknown? ? obj.attrs(false) : ['#']
    }).uniq.each { |sequence|
      @seq_strings.each { |wordseq|
        wordseq.scan(sequence) { |pos, form, classes|
          inc('Anzahl erkannter Sequenzen')

          classes.each_with_index { |wc, index|
            @buffer[pos + index].lexicals.find { |lex|
              form.gsub!(index.succ.to_s, lex.form) if lex.attr == wc
            } or break
          } or next

          deferred_insert(pos, Word.new_lexical(form, WA_SEQUENCE, LA_SEQUENCE))
        }
      }
    }

    forward_buffer
  end

  private

  def sequences(map)
    res = map.shift

    map.each { |classes|
      temp = []
      res.each { |wc1| classes.each { |wc2| temp << (wc1 + wc2) } }
      res = temp
    }

    res
  end

end
