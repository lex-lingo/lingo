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

class Lingo

=begin rdoc
== Debugger
Die Attendees von Lingo übergeben Daten über ihre Kommunikationskanäle und entweder kommt bei 
einer komplexen Konfiguration hinten das gewünschte Ergebnis raus oder aber auch nicht. Für den 
letzeren Fall ist der Debugger primär gedacht. Er kann an beliebige Stelle in den Datenstrom 
eingeschleust werden, um Schritt für Schritt zu schauen, durch welchen Attendee das Ergebnis 
verfälscht wird um so den Fehler einzugrenzen und schließlich zu lösen.

Der Debugger wird jedoch auch gerne für die Verfolgung der Verarbeitung am Bildschirm verwendet.

Achtung: Um Irritationen bei der Anwendung mehrerer Debugger zu vermeiden wird empfohlen, den 
Debugger in der Konfiguration immer unmittelbar nach dem Attendee zu platzieren, dessen Ausgabe 
debugt werden soll. Ansonsten kann es zu scheinbar unerklärlichen Interferrenzen bei der Ausgabe 
kommen.

=== Mögliche Verlinkung
Erwartet:: Daten beliebigen Typs

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee
<b>out</b>:: siehe allgemeine Beschreibung des Attendee
<b><i>eval</i></b>:: (Standard: true) Gibt eine Bedingung an, die erfüllt sein muss, damit ein 
                     Datenobjekt ausgegeben wird (siehe Beschreibung Objectfilter)
<b><i>ceval</i></b>:: (Standard: true) Gibt eiune Bedingung an, die erfüllt sein muss, damit ein 
                     Kommandoobjekt ausgegeben wird.
<b><i>prompt</i></b>:: (Standard: 'lex:) ') Gibt an, mit welchem Prefix die Ausgabe versehen werden
                       soll. Insbesondere wenn mit mehreren Debuggern gearbeitet wird, sollte dies 
                       genutzt werden.

=== Beispiele
Bei der Verarbeitung der oben angegebenen Funktionsbeschreibung des Textwriters mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader: { out: lines, files: '$(files)' }
      - debugger:   { in: lines, prompt: 'LINES:) ' }
      - tokenizer:  { in: lines, out: token }
      - debugger:   { in: token, prompt: 'TOKEN:) ' }
ergibt die Ausgabe 
  LINES:)  *FILE('test.txt')
  TOKEN:)  *FILE('test.txt')
  LINES:)  "Der Debugger kann was."
  TOKEN:)  :Der/WORD:
  TOKEN:)  :Debugger/WORD:
  TOKEN:)  :kann/WORD:
  TOKEN:)  :was/WORD:
  TOKEN:)  :./PUNC:
  TOKEN:)  *EOL('test.txt')
  LINES:)  "Lingo auch :o)"
  TOKEN:)  :Lingo/WORD:
  TOKEN:)  :auch/WORD:
  TOKEN:)  ::/PUNC:
  TOKEN:)  :o/WORD:
  TOKEN:)  :)/OTHR:
  TOKEN:)  *EOL('test.txt')
  LINES:)  *EOF('test.txt')
  TOKEN:)  *EOF('test.txt')
=end
 
 
class Attendee::Debugger < Attendee

protected

  def init
    @obj_eval = get_key('eval', 'true')
    @cmd_eval = get_key('ceval', 'true')
    @prompt = get_key('prompt', 'lex:) ')
  end
  
  
  def control(cmd, par)
    if cmd!=STR_CMD_STATUS
      puts "#{@prompt} #{AgendaItem.new(cmd, par).inspect}" if eval(@cmd_eval)
    end
  end
  
  
  def process(obj)
    puts "#{@prompt} #{obj.inspect}" if eval(@obj_eval)
  end
  
end

end
