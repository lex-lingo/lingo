# encoding: utf-8

# LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
# Mehrworterkennung und Relationierung.
#
# Copyright (C) 2005-2007 John Vorhauer
# Copyright (C) 2007-2011 John Vorhauer, Jens Wille
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
# For more information visit http://www.lex-lingo.de or contact me at
# welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
# Lex Lingo rules from here on

class Lingo

=begin rdoc
== Dehyphenizer
Der Dehyphenizer ... muss noch dokumentiert werden

=== Mögliche Verlinkung
Erwartet:: Daten vom Typ *Word* z.B. von Wordsearcher, Decomposer, Ocr_variator, Multiworder
Erzeugt:: Daten vom Typ *Word* (mit Attribut WA_MULTIWORD). Je erkannter Mehrwortgruppe wird ein zusätzliches Word-Objekt in den Datenstrom eingefügt. Z.B. für Ocr_variator, Sequencer, Noneword_filter, Vector_filter

=== Parameter
Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
Alle anderen Parameter müssen zwingend angegeben werden.
<b>in</b>:: siehe allgemeine Beschreibung des Attendee
<b>out</b>:: siehe allgemeine Beschreibung des Attendee
<b>source</b>:: siehe allgemeine Beschreibung des Dictionary
<b><i>mode</i></b>:: (Standard: all) siehe allgemeine Beschreibung des Dictionary
<b><i>stopper</i></b>:: (Standard: TA_PUNCTUATION, TA_OTHER) Gibt die Begrenzungen an, zwischen
                        denen der Multiworder suchen soll, i.d.R. Satzzeichen und Sonderzeichen,
                        weil sie kaum in einer Mehrwortgruppen vorkommen.

=== Beispiele
Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  meeting:
    attendees:
      - textreader:   { out: lines, files: '$(files)' }
      - tokenizer:    { in: lines, out: token }
      - abbreviator:   { in: token, out: abbrev, source: 'sys-abk' }
      - wordsearcher: { in: abbrev, out: words, source: 'sys-dic' }
      - decomposer:   { in: words, out: comps, source: 'sys-dic' }
      - multiworder:  { in: comps, out: multi, source: 'sys-mul' }
      - debugger:     { in: multi, prompt: 'out>' }
ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  out> *FILE('test.txt')
  out> <Sein = [(sein/s), (sein/v)]>
  out> <Name = [(name/s)]>
  out> <ist = [(sein/v)]>
  out> <johann van siegen|MUL = [(johann van siegen/m)]>
  out> <Johann = [(johann/e)]>
  out> <van = [(van/w)]>
  out> <Siegen = [(sieg/s), (siegen/v), (siegen/e)]>
  out> :./PUNC:
  out> *EOL('test.txt')
  out> *EOF('test.txt')
=end

class Attendee::Dehyphenizer < BufferedAttendee

protected

  def init
    # Parameter verwerten
    @stopper = get_array('stopper', TA_PUNCTUATION+','+TA_OTHER).collect {|s| s.upcase }

    # Wörterbuch bereitstellen
    src = get_array('source')
    mod = get_key('mode', 'all')
    @dic = Dictionary.new({'source'=>src, 'mode'=>mod}, @lingo)
    @gra = Grammar.new({'source'=>src, 'mode'=>mod}, @lingo)

    @number_of_expected_tokens_in_buffer = 2
    @eof_handling = false

    @skip = get_array('skip', "").collect { |wc| wc.downcase }
  end

  def control(cmd, par)
    @dic.report.each_pair { |key, value| set(key, value) } if cmd == STR_CMD_STATUS

    # Jedes Control-Object ist auch Auslöser der Verarbeitung
    if cmd == STR_CMD_RECORD || cmd == STR_CMD_EOF
      @eof_handling = true
      while number_of_valid_tokens_in_buffer > 1
        process_buffer
      end
      forward_number_of_token( @buffer.size, false )
      @eof_handling = false
    end
  end

  def process_buffer?
    number_of_valid_tokens_in_buffer >= @number_of_expected_tokens_in_buffer
  end

  def process_buffer
    if @buffer[0].is_a?(Word) &&
      @buffer[0].form[-1..-1] == '-' &&
      @buffer[1].is_a?(Word) &&
      !(!( ttt = @buffer[1].get_class(/./) ).nil? &&
      !@skip.index( ttt[0].attr ).nil?)

      # Einfache Zusammensetzung versuchen
      form = @buffer[0].form[0...-1] + @buffer[1].form
      word = @dic.find_word( form )
      word = @gra.find_compositum( form ) unless word.attr == WA_IDENTIFIED

      unless word.attr == WA_IDENTIFIED || (word.attr == WA_KOMPOSITUM && word.get_class('x+').empty?)
        # Zusammensetzung mit Bindestrich versuchen
        form = @buffer[0].form + @buffer[1].form
        word = @dic.find_word( form )
         word = @gra.find_compositum( form ) unless word.attr == WA_IDENTIFIED
      end

      unless word.attr == WA_IDENTIFIED || (word.attr == WA_KOMPOSITUM && word.get_class('x+').empty?)
        # Zusammensetzung mit Bindestrich versuchen
        form = @buffer[0].form + @buffer[1].form
        word = @dic.find_word( form )
        word = @gra.find_compositum( form ) unless word.attr == WA_IDENTIFIED
      end

      if word.attr == WA_IDENTIFIED || (word.attr == WA_KOMPOSITUM && word.get_class('x+').empty?)
        @buffer[0] = word
        @buffer.delete_at( 1 )
      end
    end

    # Buffer weiterschaufeln
    forward_number_of_token( 1, false )
  end

private

  # Leitet 'len' Token weiter
  def forward_number_of_token( len, count_punc = true )
    begin
      unless @buffer.empty?
        forward( @buffer[0] )
        len -= 1 unless count_punc && @buffer[0].form == CHAR_PUNCT
        @buffer.delete_at( 0 )
      end
    end while len > 0
  end

  # Liefert die Anzahl gültiger Token zurück
  def number_of_valid_tokens_in_buffer
    @buffer.collect { |token| (token.form == CHAR_PUNCT) ? nil : 1 }.compact.size
  end

end

end
