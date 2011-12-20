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
== Textwriter
Der Textwriter ermöglicht die Umleitung des Datenstroms in eine Textdatei. Dabei werden
Objekte, die nicht vom Typ String sind in eine sinnvolle Textrepresentation gewandelt.
Der Name der Ausgabedatei wird durch den Namen der Eingabedatei (des Textreaders) bestimmt.
Es kann lediglich die Extension verändert werden. Der Textwriter kann auch das LIR-Format 
erzeugen.

=== Mögliche Verlinkung
Erwartet:: Daten verschiedenen Typs

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung). 
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee
<b>out</b>:: siehe allgemeine Beschreibung des Attendee
<b><i>ext</i></b>:: (Standard: txt2) Gibt die Dateinamen-Erweiertung für die Ausgabedatei an.
                    Wird z.B. dem Textreader die Datei <tt>Dokument.txt</tt> angegeben und 
                    über die Lingo-Konfiguration alle Indexwörter herausgefiltert, kann mit 
                    <tt>ext: 'idx'</tt> der Textwriter veranlasst werden, die Indexwörter in 
                    die Datei <tt>Dokument.idx</tt> zu schreiben.
<b><i>sep</i></b>:: (Standard: ' ') Gibt an, mit welchem Trennzeichen zwei aufeinanderfolgende 
                    Objekte in der Ausgabedatei getrennt werden sollen. Gängige Werte sind auch 
                    noch '\n', welches die Ausgabe jedes Objektes in eine Zeile ermöglicht.
<b><i>lir-format</i></b>:: (Standard: false) Dieser Parameter hat keinen Wert. Wird er angegeben, 
                           dann wird er als true ausgewertet. Damit ist es möglich, die Ausgabedatei 
                           im für LIR lesbarem Format zu erstellen.

=== Beispiele
Bei der Verarbeitung der oben angegebenen Funktionsbeschreibung des Textwriters mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader:    { out: lines, files: '$(files)' }
      - tokenizer:     { in: lines, out: token }
      - wordsearcher:  { in: token, out: words, source: 'sys-dic' }
      - vector_filter: { in: words, out: filtr, sort: 'term_rel' }
      - textwriter:    { in: filtr, ext: 'vec', sep: '\n' }
ergibt die Ausgabe in der Datei <tt>test.vec</tt>
  0.03846 name
  0.01923 ausgabedatei
  0.01923 datenstrom
  0.01923 extension
  0.01923 format
  0.01923 objekt
  0.01923 string
  0.01923 textdatei
  0.01923 typ
  0.01923 umleitung
=end


class Attendee::Textwriter < Attendee

protected

  def init
    @ext = get_key('ext', 'txt2')
    @lir = get_key('lir-format', false)
    @sep = @lir ? ' ' : eval("\"#{@config['sep'] || ' '}\"")
    @no_sep, @no_puts = true, false
  end


  def control(cmd, par)
    case cmd
    when STR_CMD_LIR
      @lir = true
    when STR_CMD_FILE
      @no_sep = true

      if stdout?(@ext)
        @filename = @ext
        @file = $stdout
      else
        @filename = par.sub(/(\.[^.]+)?$/, '.'+@ext)
        @file = File.new(@filename,'w')
        inc('Anzahl Dateien')
      end
      
      @lir_rec_no = ''
      @lir_rec_buf = Array.new
      
    when STR_CMD_RECORD
      @no_sep = true
      if @lir
        flush_lir_buffer
        @lir_rec_no = par
      end
      
    when STR_CMD_EOL
      @no_sep = true
      unless @lir
        @file.puts unless @no_puts # unless @sep=="\n"
        inc('Anzahl Zeilen')
      end
      
    when STR_CMD_EOF
      flush_lir_buffer if @lir

      unless stdout?(@filename)
        @file.close
        add('Anzahl Bytes', File.stat(@filename).size)
      end
    end
  end


  def process(obj)
    if @lir
      @lir_rec_buf << (obj.kind_of?(Token) ? obj.form : obj.to_s)
    else
      @file.print @sep unless @no_sep
      @no_sep=false if @no_sep
      if obj.is_a?(Word) || obj.is_a?(Token)
        @file.print obj.form
      else
        @file.print obj
      end
    end
  end


private
  
  def flush_lir_buffer
    unless @lir_rec_no.empty? || @lir_rec_buf.empty?
      if @sep =~ /\n/
        @file.print '*', @lir_rec_no, "\n", @lir_rec_buf.join(@sep), "\n"
      else
        @file.print @lir_rec_no, '*', @lir_rec_buf.join(@sep), "\n"
      end
    end
    @lir_rec_no = ''
    @lir_rec_buf.clear
  end

  def stdout?(filename)
    %w[STDOUT -].include?(filename)
  end

end

class Attendee::Formatter < Attendee::Textwriter

  protected

  def init
    super

    @format = get_key('format', '%s')
    @map    = get_key('map', Hash.new { |h, k| h[k] = k })

    @no_puts = true
  end

  def process(obj)
    if obj.is_a?(Word) || obj.is_a?(Token)
      str = obj.form

      if obj.respond_to?(:lexicals)
        lex = obj.lexicals.first  # TODO
        att = @map[lex.attr] if lex
        str = @format % [str, lex.form, att] if att
      end
    else
      str = obj.to_s
    end

    @lir ? @lir_rec_buf << str : @file.print(str)
  end

end

end
