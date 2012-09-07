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

      KEY_REF_RE = %r{\A#{Database::KEY_REF_ESC}\d+}

      def self.open(*args)
        yield dictionary = new(*args)
      ensure
        dictionary.close if dictionary
      end

      def initialize(config, lingo)
        unless config.has_key?('source')
          raise ArgumentError, "Required parameter `source' missing."
        end

        @suffixes, @infixes = [], []

        Array(lingo.dictionary_config['suffix']).each { |t, s|
          t.downcase!

          a = t == 'f' ? @infixes : @suffixes

          s.split.each { |r|
            f, e = r.split('/')
            a << [/#{f}$/i, e || '*', t]
          }
        }

        @src = config['source'].map { |src| lingo.lexical_hash(src) }
        @all = config['mode'].nil? || config['mode'].downcase == 'all'

        lingo.dictionaries << self
      end

      def close
        @src.each { |i| i.close }
      end

      # _dic_.find_word( _aString_ ) -> _aNewWord_
      #
      # Erstellt aus dem String ein Wort und sucht nach diesem im Wörterbuch.
      def find_word(str)
        (@_word ||= {})[str] ||= Word.new(str, WA_UNKNOWN).tap { |w|
          unless (lexicals = select_with_suffix(str)).empty?
            w.lexicals = lexicals
            w.attr = WA_IDENTIFIED
          end
        }
      end

      def find_synonyms(obj, syn = [])
        lex = obj.lexicals
        lex = [obj] if lex.empty? && obj.unknown?

        com, ref = obj.attr == WA_COMPOUND, KEY_REF_RE

        lex.each { |l|
          select(l.form, syn) { |i| i =~ ref } unless com &&
            l.attr != LA_COMPOUND || l.attr == LA_SYNONYM
        }

        syn
      end

      # _dic_.select( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+)
      def select(str, lex = [])
        @src.each { |src|
          l = src[str] or next
          lex.concat(block_given? ? l.delete_if { |i| yield i } : l)
          break unless @all
        }

        lex.sort!
        lex.uniq!

        lex
      end

      # _dic_.select_with_suffix( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+).
      # Sucht dabei auch Wörter, die um wortklassenspezifische Suffixe bereinigt wurden.
      def select_with_suffix(str)
        select_with_affix(:suffix, str)
      end

      # _dic_.select_with_infix( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+).
      # Sucht dabei auch Wörter, die eine Fugung am Ende haben.
      def select_with_infix(str)
        select_with_affix(:infix, str)
      end

      # _dic_.suffix_lexicals( _aString_ ) -> _ArrayOfLexicals_
      #
      # Gibt alle möglichen Lexicals zurück, die von der Endung her auf den String anwendbar sind:
      #
      # dic.suffix_lexicals("Hasens") -> [(hasen/s), (hasen/e), (has/e)]
      def suffix_lexicals(str)
        affix_lexicals(:suffix, str)
      end

      # _dic_.gap_lexicals( _aString_ ) -> _ArrayOfLexicals_
      #
      # Gibt alle möglichen Lexicals zurück, die von der Endung her auf den String anwendbar sind:
      def infix_lexicals(str)
        affix_lexicals(:infix, str)
      end

      private

      def select_with_affix(affix, str)
        lex = select(str)

        affix_lexicals(affix, str).each { |a| select(a.form, lex) { |b|
          affix == :suffix && a.attr != b.attr
        } } if lex.empty?

        lex
      end

      def affix_lexicals(affix, str)
        lex = instance_variable_get("@#{affix}es").map { |r, e, t|
          Lexical.new("#{$`}#{e == '*' ? '' : e}#{$'}", t) if str =~ r
        }

        lex.compact!
        lex
      end

    end

  end

end
