# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2012 John Vorhauer, Jens Wille                           #
#                                                                             #
# Lingo is free software; you can redistribute it and/or modify it under the  #
# terms of the GNU Affero General Public License as published by the Free     #
# Software Foundation; either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# Lingo is distributed in the hope that it will be useful, but WITHOUT ANY    #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for     #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with Lingo. If not, see <http://www.gnu.org/licenses/>.               #
#                                                                             #
###############################################################################
#++

class Lingo

  module Language

    class Dictionary

      include Cachable
      include Reportable

      def initialize(config, lingo)
        init_reportable
        init_cachable

        dictionary_config = lingo.dictionary_config

        # Parameter prüfen
        raise "Keine Sprach-Konfiguration angegeben!" if dictionary_config.nil?
        raise "Keine Parameter angegeben!" if config.nil?
        raise "Keine Datenquellen angegeben!" unless config.has_key?('source')

        # Parameter auslesen
        @all_sources = (config['mode'].nil? || config['mode'].downcase=='all')

        @sources = config['source'].map { |src| lingo.lexical_hash(src) }

        lingo.dictionaries << self

        # Parameter aus de.lang:language/dictionary auslesen
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

      def close
        @sources.each(&:close)
      end

      def report
        super.tap { |rep| @sources.each { |src| rep.update(src.report) } }
      end

      # _dic_.find_word( _aString_ ) -> _aNewWord_
      #
      # Erstellt aus dem String ein Wort und sucht nach diesem im Wörterbuch.
      def find_word(string)
        # Cache abfragen
        key = string.downcase
        if hit?(key)
          inc('cache hits')
          word = retrieve(key)
          word.form = string
          return word
        end

        word = Word.new(string, Language::WA_UNKNOWN)
        lexicals = select_with_suffix(string)
        unless lexicals.empty?
          word.lexicals = lexicals
          word.attr = Language::WA_IDENTIFIED
        end
        store(key, word)
      end

      def find_synonyms(obj)
        # alle Lexicals des Wortes
        lexis = obj.lexicals
        lexis = [obj] if lexis.empty? && obj.attr==Language::WA_UNKNOWN
        # alle gefundenen Synonyme
        synos = []
        # multiworder optimization
        key_ref = %r{\A#{Regexp.escape(Database::KEY_REF)}\d+}o

        lexis.each do |lex|
          # Synonyme für Teile eines Kompositum ausschließen
          next if obj.attr==Language::WA_KOMPOSITUM && lex.attr!=Language::LA_KOMPOSITUM
          # Synonyme für Synonyme ausschließen
          next if lex.attr==Language::LA_SYNONYM

          select(lex.form).each do |syn|
            synos << syn unless syn =~ key_ref
          end
        end

        synos
      end

      # _dic_.select( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+)
      def select(string)
        lexicals = []

        @sources.each { |src|
          if lexis = src[string]
            lexicals += lexis
            break unless @all_sources
          end
        }

        lexicals.sort.uniq
      end

      # _dic_.select_with_suffix( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+).
      # Sucht dabei auch Wörter, die um wortklassenspezifische Suffixe bereinigt wurden.
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

      # _dic_.select_with_infix( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+).
      # Sucht dabei auch Wörter, die eine Fugung am Ende haben.
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

      # _dic_.suffix_lexicals( _aString_ ) -> _ArrayOfLexicals_
      #
      # Gibt alle möglichen Lexicals zurück, die von der Endung her auf den String anwendbar sind:
      #
      # dic.suffix_lexicals("Hasens") -> [(hasen/s), (hasen/e), (has/e)]
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

      # _dic_.gap_lexicals( _aString_ ) -> _ArrayOfLexicals_
      #
      # Gibt alle möglichen Lexicals zurück, die von der Endung her auf den String anwendbar sind:
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

  end

end
