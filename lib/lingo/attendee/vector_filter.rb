# encoding: utf-8

#--
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
#++

class Lingo

  # Die Hauptaufgabe des Vector_filter ist die Erstellung eines Dokumenten-Index-Vektor.
  # Dabei werden die durch die anderen Attendees ermittelten Grundformen eines Wortes
  # gespeichert und bei einem Datei- oder Record-Wechsel weitergeleitet. Der Vector_filter
  # kann bestimmte Wortklassen filtern und die Ergebnisse in verschiedenen Arten aufbereiten.
  # Dabei werden Funktionen wie das einfache Zählen der Häufigkeit innerhalb eines Dokuments,
  # aber auch die Term-Frequenz und unterschiedliche Ausgabeformate unterstützt.
  #
  # === Mögliche Verlinkung
  # Erwartet:: Daten vom Typ *Word*, z.B. von Abbreviator, Wordsearcher, Decomposer, Synonymer, Multiworder, Sequencer
  # Erzeugt:: Daten vom Typ *String*, z.B. für Textwriter
  #
  # === Parameter
  # Kursiv dargestellte Parameter sind optional (ggf. mit Angabe der Voreinstellung).
  # Alle anderen Parameter müssen zwingend angegeben werden.
  # <b>in</b>:: siehe allgemeine Beschreibung des Attendee
  # <b>out</b>:: siehe allgemeine Beschreibung des Attendee
  # <b><i>lexicals</i></b>:: (Standard: '[sy]' => die Wortklassen Substantiv und Synonyme werden gefiltert)
  #                          Es können in eckige Klammern beliebige Wortklassen angegeben werden (siehe lib/strings.rb).
  #                          Der Parameter wird als regulärer Ausdruck ausgewertet.
  # <b><i>sort</i></b>:: (Standard: 'normal')
  #                      Der Parameter +sort+ beeinflußt Verarbeitung und Ausgabeformat des Vector_filters.
  #                      normal:: Jedes gefilterte Wort wird einmalig (keine Doppelnennungen!) in
  #                               alphabetischer Reihenfolge in der Form "wort" ausgegeben.
  #                      term_abs:: Jedes gefilterte Wort wird einmalig in absteigender Häufigkeit mit Angabe
  #                                 der absoluten Häufigkeit im Dokument in der Form "12 wort" ausgegeben.
  #                      term_rel:: Jedes gefilterte Wort wird einmalig in absteigender Häufigkeit mit Angabe
  #                                 der relativen Häufigkeit im Dokument in der Form "0.1234 wort" ausgegeben.
  #                      sto_abs:: Jedes gefilterte Wort wird einmalig in absteigender Häufigkeit mit Angabe
  #                                der absoluten Häufigkeit im Dokument in der Form "wort {12}" ausgegeben.
  #                      sto_rel:: Jedes gefilterte Wort wird einmalig in absteigender Häufigkeit mit Angabe
  #                                der relativen Häufigkeit im Dokument in der Form "wort {0.1234}" ausgegeben.
  # <b><i>skip</i></b>:: (Standard: TA_PUNCTUATION und TA_OTHER) Hiermit wird angegeben, welche Objekte nicht
  #                      verarbeitet werden sollen. Die +skip+-Angabe bezieht sich auf das Attribut +attr+ von
  #                      Token oder Word-Objekten.
  #
  # === Beispiele
  # Bei der Verarbeitung einer normalen Textdatei mit der Ablaufkonfiguration <tt>t1.cfg</tt>
  #   meeting:
  #     attendees:
  #       - textreader:   { out: lines, files: '$(files)' }
  #       - tokenizer:    { in: lines, out: token }
  #       - wordsearcher: { in: token, out: words, source: 'sys-dic' }
  #       - vector_filter: { in: words, out: filtr, sort: 'term_rel' }
  #       - debugger:     { in: filtr, prompt: 'out>' }
  # ergibt die Ausgabe über den Debugger: <tt>lingo -c t1 test.txt</tt>
  #   out> *FILE('test.txt')
  #   out> "0.28571 indexierung"
  #   out> *EOF('test.txt')

  class Attendee::Vector_filter < Attendee

    protected

    def init
      @lexis = Regexp.new(get_key('lexicals', '[sy]').downcase)
      @sort = get_key('sort', 'normal').downcase
      @skip = get_array('skip', TA_PUNCTUATION+','+TA_OTHER).collect {|s| s.upcase }
      @vectors = Array.new
      @word_count = 0

      if @debug = get_key('debug', false)
        @prompt = get_key('prompt', 'lex:) ')
      end
    end

    def control(cmd, par)
      case cmd
        when STR_CMD_EOL
          deleteCmd
        when STR_CMD_FILE, STR_CMD_RECORD, STR_CMD_EOF
          @debug ? @vectors.each { |str| forward(str) } : sendVector
          @vectors.clear
      end
    end

    def process(obj)
      if @debug
        @vectors << "#{@prompt} #{obj.inspect}" if eval(@debug)
      elsif obj.is_a?(Word)
        @word_count += 1 if @skip.index(obj.attr).nil?
        unless obj.lexicals.nil?
          lexis = obj.get_class(@lexis) #lexicals.collect { |lex| (lex.attr =~ @lexis) ? lex : nil }.compact # get_class(@lexis)
          lexis.each { |lex| @vectors << lex.form.downcase }
          add('Anzahl von Vektor-Wörtern', lexis.size)
        end
      end
    end

    private

    def sendVector
      return if @vectors.size==0

      add('Objekte gefiltert', @vectors.size)

      # Array der Vector-Wörter zählen und nach Häufigkeit sortieren
      if @sort=='normal'
        @vectors = @vectors.compact.sort.uniq
      else
        cnt = Hash.new(0)
        @vectors.compact.each { |e| cnt[e]+=1 }
        @vectors = cnt.to_a.sort { |x,y|
          if (y[1]<=>x[1])==0
            x[0]<=>y[0]
          else
            y[1]<=>x[1]
          end
        }
      end

      # Vectoren je nach Parameter formatiert weiterleiten
      @vectors.collect { |vec|
        case @sort
        when 'term_abs' then sprintf "%d %s", vec[1], vec[0]
        when 'term_rel' then sprintf "%6.5f %s", vec[1].to_f/@word_count, vec[0]
        when 'sto_abs'  then sprintf "%s {%d}", vec[0], vec[1]
        when 'sto_rel'  then sprintf "%s {%6.5f}", vec[0], vec[1].to_f/@word_count
        else sprintf "%s", vec
        end
      }.each { |str| forward(str) }

      @word_count = 0 if @sort == 'sto_rel'
    end

  end

end
