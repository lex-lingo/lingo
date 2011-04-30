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
== Tokenizer
Der Tokenizer zerlegt eine Textzeile in einzelne Token. Dies ist notwendig,
damit nachfolgende Attendees die Textdatei häppchenweise verarbeiten können.

=== Mögliche Verlinkung
Erwartet:: Daten des Typs *String* (Textzeilen) z.B. von Textreader
Erzeugt:: Daten des Typs *Token* z.B. für Abbreviator, Wordsearcher

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee.
<b>out</b>:: siehe allgemeine Beschreibung des Attendee

=== Konfiguration
Der Tokenizer benötigt zur Identifikation einzelner Token Regeln, nach denen er 
arbeiten soll. Die benötigten Regeln werden aufgrund des Umfangs nicht als Parameter,
sondern in der Sprachkonfiguration hinterlegt, die sich standardmäßig in der Datei
<tt>de.lang</tt> befindet (YAML-Format).
  language:
    attendees:
      tokenizer:
        regulars:
          - _CHR_: '\wÄÖÜÁÂÀÉÊÈÍÎÌÓÔÒÚÛÙÝäöüáâàéêèíîìóôòúûùý'
          - NUMS:  '[+-]?(\d{4,}|\d{1,3}(\.\d{3,3})*)(\.|(,\d+)?%?)'
          - URLS:  '((mailto:|(news|http|https|ftp|ftps)://)\S+|^(www(\.\S+)+)|\S+([\._]\S+)+@\S+(\.\S+)+)'
          - ABRV:  '(([_CHR_]+\.)+)[_CHR_]+'
          - ABRS:  '(([_CHR_]{1,1}\.)+)(?!\.\.)'
          - WORD:  '[_CHR_\d]+'
          - PUNC:  '[!,\.:;?]'
          - OTHR:  '[!\"#$%&()*\+,\-\./:;<=>?@\[\\\]^_`{|}~´]'
          - HELP:  '.*'
Die Regeln werden in der angegebenen Reihenfolge abgearbeitet, solange bis ein Token 
erkannt wurde. Sollte keine Regel zutreffen, so greift die letzt Regel +HELP+ in jedem 
Fall.
Regeln, deren Name in Unterstriche eingefasst sind, werden als Makro interpretiert. 
Makros werden genutzt, um lange oder sich wiederholende Bestandteile von Regeln
einmalig zu definieren und in den Regeln über den Makronamen eine Auflösung zu forcieren.
Makros werden selber nicht für die Erkennung von Token eingesetzt.

=== Generierte Kommandos
Damit der nachfolgende Datenstrom einwandfrei verarbeitet werden kann, generiert der Tokenizer
Kommandos, die mit in den Datenstrom eingefügt werden. 
<b>*EOL(<dateiname>)</b>:: Kennzeichnet das Ende einer Textzeile, da die Information ansonsten 
für nachfolgende Attendees verloren wäre.

=== Beispiele
Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader: { out: lines, files: '$(files)' }
      - tokenizer:  { in: lines, out: token }
      - debugger:   { in: token, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt> 
  out> *FILE('test.txt')
  out> :Dies/WORD:
  out> :ist/WORD:
  out> :eine/WORD:
  out> :Zeile/WORD:
  out> :./PUNC:
  out> *EOL('test.txt')
  out> :Dies/WORD:
  out> :ist/WORD:
  out> :noch/WORD:
  out> :eine/WORD:
  out> :./PUNC:
  out> *EOL('test.txt')
  out> *EOF('test.txt')
=end


class Attendee::Tokenizer < Attendee

protected

  def init
    #  Regular Expressions für Token-Erkennung einlesen
    regulars = get_key('regulars', '')
    forward(STR_CMD_ERR, 'regulars nicht definiert') if regulars.nil?

    @space = get_key('space', false)

    #  Mit _xxx_ gekennzeichnete Makros anwenden und Expressions ergänzen und umwandeln
    macros = {}
    @rules = [['SPAC', /^\s+/]]

    regulars.each { |rule|
      name = rule.keys[0]
      expr = rule.values[0].gsub(/_(\w+?)_/) {
        macros[$&] || begin
          Object.const_get("UTF_8_#{$1.upcase}")
        rescue NameError
        end
      }

      if name =~ /^_\w+_$/    #    is a macro
        macros[name] = expr if name =~ /^_\w+_$/
      else
        @rules << [name, Regexp.new('^'+expr)]
      end
    }

    #  Der Tokenizer gibt jedes Zeilenende als Information weiter, sofern es sich 
    #  nicht um die Verarbeitung einer LIR-Datei handelt. Im Falle einer normalen Datei
    #  wird der Dateiname gespeichert und als Kennzeichen für die Erzeugung von 
    #  Zeilenende-Nachrichten herangezogen.
    @filename = nil
  end


  def control(cmd, param)
    case cmd
        when STR_CMD_FILE then @filename = param
        when STR_CMD_LIR  then @filename = nil
    end
  end


  def process(obj)
    if obj.is_a?(String)
      inc('Anzahl Zeilen')
      tokenize(obj).each { |token|
        inc('Anzahl Muster '+token.attr)
        inc('Anzahl Token')
        forward(token) 
      }
      forward(STR_CMD_EOL, @filename) unless @filename.nil?
    else
      forward(obj)
    end
  end


private

  #  tokenize("Eine Zeile.")  ->  [:Eine/WORD:, :Zeile/WORD:, :./PUNC:]
  def tokenize(textline)
    rule = name = expr = nil
    token = []
    until textline.empty?
      @rules.each { |rule|
        name, expr = rule
        if textline =~ expr
          token << Token.new($~[0], name) if name != 'SPAC' || @space
          textline = $'
          break
        end
      }
    end
    token
  end

end
