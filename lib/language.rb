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


require 'lib/const'
require 'lib/modules'
require 'lib/database'
#require 'lib/utilities'

=begin rdoc
== LexicalHash
Die Klasse LexicalHash ermöglicht den Zugriff auf die Lingodatenbanken. Im Gegensatz zur
Klasse DbmFile, welche nur Strings als Ergebnis zurück gibt, wird hier als Ergebnis ein
Array von Lexical-Objekten zurück gegeben.
=end
class LexicalHash
  include Cachable
  include Reportable

private

  def initialize( id )
    init_reportable
    init_cachable
    report_prefix( id )
    
    #  Parameter aus de.lang:language/dictionary/databases auslesen
    config = Lingo.config['language/dictionary/databases/' + id]
    Lingo.error( "LexicalHash kann Datenquelle mit ID '#{id}' in de.lang:language/dictionary/databases' nicht finden" ) if config.nil?
    
    @wordclass = config.fetch( 'def-wc', LA_UNKNOWN )

    #  Store erzeugen
    @source = DbmFile.new( id )
    @source.open
  end


public

  def close
    @source.close
  end    


  def [](ikey)
    #  Schlüssel normalisieren
    inc('total requests')
    key = ikey.downcase
    
    #  Cache abfragen
    if hit?(key)
      inc('cache hits')
      return retrieve(key)
    end

    #  Wert aus Datenbank lesen 
    inc('source reads')
    record = @source[key]

    #  Werte in interne Objekte umwandeln
    record = record.collect do |str|
      case str
      #  Hinweis für Multiworder, dass Multiword mit (\d) Wörtern länge zu prüfen ist
      when /^\*\d+$/          then str
      #  Alleinige Angabe der Wortklasse => Ergebniswort ist gleich dem Schlüssel
      when /^#(.)$/            then Lexical.new(key, $1)
      #  Angabe Ergebniswort und Wortklasse
      when /^([^#]+?)\s*#(.)$/  then Lexical.new($1, $2)
      #  Angabe Ergebniswort ohne Wortklasse
      when /^([^#]+)$/        then Lexical.new( $1, @wordclass )
      else  str
      end
    end.compact.sort.uniqual unless record.nil?

    #  Ergebnis zurückgeben
    inc('data found') unless record.nil?
    store(key, record)
  end

end



class Dictionary
  include Cachable
  include Reportable

  @@opened = []

private
  def initialize(config, dictionary_config)
    init_reportable
    init_cachable
    
    #  Parameter aus de.lang:language/dictionary/databases auslesen
#    config = Lingo.config['language/dictionary/databases/' + id]

    #  Parameter prüfen
    raise "Keine Sprach-Konfiguration angegeben!" if dictionary_config.nil?
    raise "Keine Parameter angegeben!" if config.nil?
    raise "Keine Datenquellen angegeben!" unless config.has_key?('source')

    #  Parameter auslesen
    @all_sources = (config['mode'].nil? || config['mode'].downcase=='all')

    @sources = config['source'].collect { |src|
      LexicalHash.new( src )
    }

    @@opened << self
  
    #  Parameter aus de.lang:language/dictionary auslesen
    @suffixes = []
    @infixes = []
    
    dictionary_config['suffix'].each {|arr|
      typ, sufli = arr
      typ.downcase!
      sufli.split.each {|suf|
        su, ex = suf.split('/')
        fix = [Regexp.new(su+'$', 'i'), ex.nil? ? '*' : ex, typ]
        (typ=='f' ? @infixes : @suffixes) << fix
      }
    } if dictionary_config.has_key?( 'suffix' )
  end

public
  def Dictionary.close!
    @@opened.each { |dict|
      dict.close
    }
  end

  def close
    @sources.each do |src|
      src.close 
    end
  end    


  alias_method :report_dictionary, :report
  def report
    rep = report_dictionary
    @sources.each { |src|
      rep.update(src.report)
    }
    rep
  end


  #    _dic_.find_word( _aString_ ) -> _aNewWord_
  #
  #    Erstellt aus dem String ein Wort und sucht nach diesem im Wörterbuch.
  def find_word(string)
    #  Cache abfragen
    key = string.downcase
    if hit?(key)
      inc('cache hits')
      word = retrieve(key)
      word.form = string
      return word
    end

    word = Word.new(string, WA_UNKNOWN)
    lexicals = select_with_suffix(string)
    unless lexicals.empty?
      word.lexicals = lexicals
      word.attr = WA_IDENTIFIED 
    end
    store(key, word)
  end

  def find_synonyms(obj)
    #  alle Lexicals des Wortes
    lexis = obj.lexicals
    lexis = [obj] if lexis.empty? && obj.attr==WA_UNKNOWN
    #  alle gefundenen Synonyme
    synos = []
    #  multiworder optimization
    key_ref = %r{\A#{Regexp.escape(KEY_REF)}\d+}o

    lexis.each do |lex|
      #  Synonyme für Teile eines Kompositum ausschließen
      next if obj.attr==WA_KOMPOSITUM && lex.attr!=LA_KOMPOSITUM
      #  Synonyme für Synonyme ausschließen
      next if lex.attr==LA_SYNONYM

      select(lex.form).each do |syn|
        synos << syn unless syn =~ key_ref
      end
    end

    synos
  end

  #    _dic_.select( _aString_ ) -> _ArrayOfLexicals_
  #
  #    Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+)
  def select(string)
    lexicals = []
    
    @sources.each do |src|
      unless (lexis=src[string]).nil?
        lexicals += lexis
        break unless @all_sources
      end
    end

#v TODO: v1.5.1
#v    lexicals.sort.uniqual
# TODO: anders lösen
    lex = lexicals.collect { |i| i.is_a?(Lexical) ? i : nil }.compact.sort.uniqual
    txt = lexicals.collect { |i| i.is_a?(String) ? i : nil }.compact.sort.uniq
#  p lex+txt
    lex+txt
#v
  end


  #    _dic_.select_with_suffix( _aString_ ) -> _ArrayOfLexicals_
  #
  #    Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+).
  #    Sucht dabei auch Wörter, die um wortklassenspezifische Suffixe bereinigt wurden.
  def select_with_suffix(string)
    lexicals = select(string)
    if lexicals.empty?
      suffix_lexicals(string).each { |suflex|
        select(suflex.form).each { |srclex|
          lexicals << srclex if suflex.attr == srclex.attr
        }
      }
    end
    lexicals
  end


  #    _dic_.select_with_infix( _aString_ ) -> _ArrayOfLexicals_
  #
  #    Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+).
  #    Sucht dabei auch Wörter, die eine Fugung am Ende haben.
  def select_with_infix(string)
    lexicals = select(string)
    if lexicals.size == 0
      infix_lexicals(string).each { |inlex|
        select(inlex.form).each { |srclex|
          lexicals << srclex
        }
      }
    end
    lexicals
  end


  #    _dic_.suffix_lexicals( _aString_ ) -> _ArrayOfLexicals_
  #
  #    Gibt alle möglichen Lexicals zurück, die von der Endung her auf den String anwendbar sind:
  #
  #    dic.suffix_lexicals("Hasens") -> [(hasen/s), (hasen/e), (has/e)]
  def suffix_lexicals(string)
    lexicals = []
    newform = regex = ext = type = nil
    @suffixes.each { |suf|
      regex, ext, type = suf
      if string =~ regex
        newform = $`+((ext=="*")?'':ext)+$'
        lexicals << Lexical.new(newform, type)
      end
    }
    lexicals
  end


  #    _dic_.gap_lexicals( _aString_ ) -> _ArrayOfLexicals_
  #
  #    Gibt alle möglichen Lexicals zurück, die von der Endung her auf den String anwendbar sind:
  def infix_lexicals(string)
    lexicals = []
    newform = regex = ext = type = nil
    @infixes.each { |suf|
      regex, ext, type = suf
      if string =~ regex
        newform = $`+((ext=="*")?'':ext)+$'
        lexicals << Lexical.new(newform, type)
      end
    }
    lexicals
  end

end



class Compositum
end



=begin rdoc
== Grammar
Die Klasse Grammar beinhaltet grammatikalische Spezialitäten einer Sprache. Derzeit findet die 
Kompositumerkennung hier ihren Platz, die mit der Methode find_compositum aufgerufen werden kann.
Die Klasse Grammar wird genau wie ein Dictionary initialisiert. Das bei der Initialisierung angegebene Wörterbuch ist Grundlage 
für die Erkennung der Kompositumteile.
=end

class Grammar
    #   Ergebnisse der Kompositumerkennung werden gespeichert und bei erneutem Aufruf mit gleichem Suchwort genutzt
    include Cachable

    #   Die Verarbeitung wird statistisch erfasst und mit der Option -s angezeigt
    include Reportable

private

    #   initialize(config, dictionary_config) -> _Grammar_
    #   config = Attendee-spezifische Parameter 
    #   dictionary_config = Datenbankkonfiguration aus de.lang
    def initialize(config, dictionary_config)
        init_reportable
        init_cachable
    
        @dictionary = Dictionary.new(config, dictionary_config)
    
        #   Sprachspezifische Einstellungen für Kompositumverarbeitung laden (die nachfolgenden Werte können in der
        #   Konfigurationsdatei de.lang nach belieben angepasst werden)
        comp = dictionary_config['compositum']
    
        #   Ein Wort muss mindestens 8 Zeichen lang sein, damit überhaupt eine Prüfung stattfindet.
        @comp_min_word_size = (comp['min-word-size'] || '8').to_i
    
         #   Die durchschnittliche Länge der Kompositum-Wortteile muss mindestens 4 Zeichen lang sein, sonst ist es kein 
         #   gültiges Kompositum.
        @comp_min_avg_part_size = (comp['min-avg-part-size'] || '4').to_i
          
        #   Der kürzeste Kompositum-Wortteil muss mindestens 1 Zeichen lang sein
        @comp_min_part_size = (comp['min-part-size'] || '1').to_i
    
        #   Ein Kompositum darf aus höchstens 4 Wortteilen bestehen
        @comp_max_parts = (comp['max-parts'] || '4').to_i
    
        #   Die Wortklasse eines Kompositum-Wortteils kann separat gekennzeichnet werden, um sie von Wortklassen normaler Wörter
        #   unterscheiden zu können z.B. Hausmeister => ['haus/s', 'meister/s'] oder Hausmeister => ['haus/s+', 'meister/s+'] mit
        #   append-wordclass = '+' 
        @append_wc = comp.fetch( 'append-wordclass', '' )
    
        #   Bestimmte Sequenzen können als ungültige Komposita erkannt werden, z.B. ist ein Kompositum aus zwei Adjetiven kein
        #   Kompositum, also skip-sequence = 'aa'
        @sequences = comp.fetch( 'skip-sequences', [] ).collect { |sq| sq.downcase }

        #   Liste der Vorschläge für eine Zerlegung
        @suggestions = []
    end



public

    def close
        @dictionary.close 
    end    
  
    alias_method :report_grammar, :report
    
     def report
        rep = report_grammar
        rep.update(@dictionary.report)
        rep
     end


    #   find_compositum(string) -> word wenn level=1
    #    find_compositum(string) -> [lexicals, stats] wenn level!=1
    #
    #   find_compositum arbeitet in verschiedenen Leveln, da die Methode auch rekursiv aufgerufen wird. Ein Level größer 1 
    #   entspricht daher einem rekursiven Aufruf
    def find_compositum(string, level=1, has_tail=false)
  
        #   Prüfen, ob string bereits auf Kompositum getestet wurde. Wenn ja, dann Ergebnis des letztes Aufrufs zurück geben.
        key = string.downcase
        if level == 1 && hit?(key)
            inc('cache hits')
            return retrieve(key)
        end
    
        #   Ergebnis vorbelegen
        comp = Word.new(string, WA_UNKNOWN)
    
        #    Validitätsprüfung: nur Strings mit Mindestlänge auf Kompositum prüfen
        if string.size <= @comp_min_word_size
            inc('String zu kurz')
            return (level==1) ? comp : [[],[],'']
        end
    
        #    Kompositumerkennung initialisieren
        inc('Komposita geprüft')
        stats, lexis, seqs = permute_compositum(string.downcase, level, has_tail)

        if level==1
            #   Auf Level 1 Kompositum zurück geben
            if lexis.size > 0 && is_valid?( string, stats, lexis, seqs )
                inc('Komposita erkannt')
                comp.attr = WA_KOMPOSITUM
                comp.lexicals = lexis.collect do |lex|
                    (lex.attr==LA_KOMPOSITUM) ? lex : Lexical.new(lex.form, lex.attr+@append_wc)
                end
            end
            
            return store(key, comp)
        end
        
        #  Validitätsprüfung
        if lexis.size > 0 && is_valid?(string, stats, lexis, seqs)
            return [stats, lexis, seqs]
        else
            return [[],[],'']
        end
        
    end


private
    
    def is_valid?(string, stats, lexis, seqs)
        is_valid = true
        is_valid &&= (stats.size <= @comp_max_parts)
        is_valid &&= (stats.sort[0] >= @comp_min_part_size)
        is_valid &&= (string.size/stats.size) >= @comp_min_avg_part_size
        is_valid &&= @sequences.index( seqs ).nil? unless @sequences.empty?
        is_valid
    end
    
    #    permute_string( _aString_ ) ->  [lexicals, stats, seqs]
    #
    def permute_compositum(string, level, has_tail)
        @suggestions[level] = [] if @suggestions[level].nil?
        
        #  Finde letzten Bindesstrich im Wort
        if string =~ /^(.+)-([^-]+)$/
            return test_compositum($1, '-', $2, level, has_tail)
        else
            #  Wortteilungen testen
            1.upto(string.size-1) do |p|
                #   String teilen und testen
                fr_str, ba_str = string.split(p)
                stats, lexis, seqs = test_compositum(fr_str, '', ba_str, level, has_tail)

                unless lexis.empty?
                    if lexis[-1].attr==LA_TAKEITASIS
                        #  => halbes Kompositum
                        @suggestions[level] << [stats, lexis, seqs]
                    else
                         #  => ganzes Kompositum
                        return [stats, lexis, seqs]
                     end        
                 end
             end
            
             #  alle Wortteilungen durchprobiert und noch immer kein definitives Kompositum erkannt. Dann nehme besten Vorschlag.
            if @suggestions[level].empty?
                return [[],[],'']
            else
                stats, lexis, seqs = @suggestions[level][0]
                @suggestions[level].clear
                return [stats, lexis, seqs]
            end
        end
    end


    #    test_compositum() ->  [stats, lexicals, seq]
    #
    #    Testet einen definiert zerlegten String auf Kompositum
    def test_compositum(front_string, infix, back_string, level, has_tail)
        #  Statistik merken für Validitätsprüfung
        stats = [front_string.size, back_string.size]
        seqs = ['?', '?']
        
         #  zuerst hinteren Teil auflösen
        #  1. Möglichkeit:  Wort mit oder ohne Suffix
        back_lexicals = @dictionary.select_with_suffix(back_string)
        unless back_lexicals.empty?
            back_form = has_tail ? back_string : back_lexicals.sort[0].form
            seqs[1] = back_lexicals.sort[0].attr
        end
            
        #  2. Möglichkeit:  Wort mit oder ohne Infix, wenn es nicht der letzte Teil des Wortes ist
        if back_lexicals.empty? && has_tail
            back_lexicals = @dictionary.select_with_infix(back_string)
            unless back_lexicals.empty?
                back_form = back_string
                seqs[1] = back_lexicals.sort[0].attr
            end
        end
        
        #  3. Möglichkeit:  Selber ein Kompositum (nur im Bindestrich-Fall!)
        if back_lexicals.empty? && infix=='-'
            back_stats, back_lexicals, back_seqs = find_compositum(back_string, level+1, has_tail)
            unless back_lexicals.empty?
                back_form = back_lexicals.sort[0].form
                seqs[1] = back_seqs
                stats = stats[0..0] + back_stats
            end
        end
          
        #  4. Möglichkeit:  Take it as is [Nimm's, wie es ist] (nur im Bindestrich-Fall!)
        if back_lexicals.empty? && infix=='-'
            back_lexicals = [Lexical.new(back_string, LA_TAKEITASIS)]
            back_form = back_string
            seqs[1] = back_lexicals.sort[0].attr
        end
        
        #  wenn immer noch nicht erkannt, dann sofort zurück
        return [[],[],''] if back_lexicals.empty?
        
    
        #  dann vorderen Teil auflösen
        #
        #  1. Möglichkeit:  Wort mit oder ohne Infix
        front_lexicals = @dictionary.select_with_infix(front_string)
        unless front_lexicals.empty?
            front_form = front_string
            seqs[0] = front_lexicals.sort[0].attr
        end
        
        #  2. Möglichkeit:  Selber ein Kompositum
        if front_lexicals.empty?
            front_stats, front_lexicals, front_seqs = find_compositum(front_string, level+1, true)
            unless front_lexicals.empty?
                front_form = front_lexicals.sort[0].form
                seqs[0] = front_seqs
                stats = front_stats + stats[1..-1]
            end
        end
        
        #  3. Möglichkeit:  Take it as is [Nimm's, wie es ist] (nur im Bindestrich-Fall!)
        if front_lexicals.empty? && infix=='-'
            front_lexicals = [Lexical.new(front_string, LA_TAKEITASIS)]
            seqs[0] = front_lexicals.sort[0].attr
            front_form = front_string
        end
        
        #  wenn immer noch nicht erkannt, dann sofort zurück
        return [[],[],''] if front_lexicals.empty?
        
        
        #  Kompositum gefunden, Grundform bilden
        lexis = (front_lexicals + back_lexicals).collect { |lex|
          (lex.attr==LA_KOMPOSITUM) ? nil : lex
        }.compact
        lexis << Lexical.new(front_form + infix + back_form, LA_KOMPOSITUM)
        
        return [stats, lexis.sort, seqs.join ]
    
    end

end
