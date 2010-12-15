# encoding: utf-8

#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005-2007 John Vorhauer
#  Copyright (C) 2007-2010 John Vorhauer, Jens Wille
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
== Objectfilter
Der Objectfilter ermöglicht es, beliebige Objekte aus dem Datenstrom herauszufiltern.
Um die gewünschten Objekte zu identifizieren, sind ein paar Ruby-Kenntnisse und das Wissen
um die Lingo Klassen notwendig. Hier sollen kurz die häufigsten Fälle angesprochen werden:

Filtern nach einem bestimmten Typ, z.B. Token oder Word wird beispielsweise durch den Ausdruck
'obj.kind_of?(Word)' ermöglicht. Token und Words haben jeweils ein Attribut +attr+. 
Bei Token gibt +attr+ an, mit welcher Tokenizer-Regel das Token erkannt wurde. So können z.B. 
alle numerischen Token mit dem Ausdruck 'obj.kind_of?(Token) && obj.attr=="NUMS"' identifiziert 
werden. Wie bereits gezeigt, können Bedingungen durch logisches UND (&&) oder ODER (||) verknüpft werden.
Das Attribut +form+ kann genutzt werden, um auf den Text eines Objektes zuzugreifen, z.B. 
'obj.form=="John"'.

=== Mögliche Verlinkung
Erwartet:: Daten beliebigen Typs von allen Attendees
Erzeugt:: Daten, die der als Parameter übergebenen Bedingung entsprechen

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee
<b>out</b>:: siehe allgemeine Beschreibung des Attendee
<b><i>objects</i></b>:: (Standard: true) Gibt einen Ruby-Ausdruck an, der, wenn der Ausdruck 
                        als Wahr ausgewertet wird, das Objekt weiterleitet und ansonsten filtert.

=== Beispiele
Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader:   { out: lines, files: '$(files)' }
      - tokenizer:    { in: lines, out: token }
      - wordsearcher: { in: token, out: words, source: 'sys-dic' }
      - objectfilter: { in: words, out: filtr, objects: 'obj.kind_of?(Word) && obj.lexicals.size>0 && obj.lexicals[0].attr==LA_SUBSTANTIV' }
      - debugger:     { in: filtr, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  out> *FILE('test.txt')
  out> <Indexierung = [(indexierung/s)]>
  out> <Indexierung = [(indexierung/s)]>
  out> *EOL('test.txt')
  out> *EOF('test.txt')
=end


class Attendee::Objectfilter < Attendee

protected

  def init
    @obj_eval = get_key('objects', 'true')
  end

  
  def process(obj)
    forward(obj) if eval(@obj_eval)
  end
  
end
