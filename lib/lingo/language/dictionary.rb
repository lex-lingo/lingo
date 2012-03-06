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

      def self.open(*args)
        yield dictionary = new(*args)
      ensure
        dictionary.close if dictionary
      end

      def initialize(config, lingo)
        unless config.has_key?('source')
          raise ArgumentError, 'Required parameter `source\' missing.'
        end

        init_cachable
        init_reportable

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
        @src.each(&:close)
      end

      def report
        super.tap { |rep| @src.each { |src| rep.update(src.report) } }
      end

      # _dic_.find_word( _aString_ ) -> _aNewWord_
      #
      # Erstellt aus dem String ein Wort und sucht nach diesem im Wörterbuch.
      def find_word(str)
        if hit?(key = str.downcase)
          inc('cache hits')
          return retrieve(key).tap { |word| word.form = str }
        end

        word = Word.new(str, WA_UNKNOWN)

        unless (lexicals = select_with_suffix(str)).empty?
          word.lexicals = lexicals
          word.attr = WA_IDENTIFIED
        end

        store(key, word)
      end

      def find_synonyms(obj)
        lex = obj.lexicals
        lex = [obj] if lex.empty? && obj.unknown?

        # multiworder optimization
        ref = %r{\A#{Database::KEY_REF_ESC}\d+}

        lex.each_with_object([]) { |l, s|
          next if l.attr == LA_SYNONYM
          next if l.attr != LA_COMPOUND && obj.attr == WA_COMPOUND

          select(l.form).each { |y| s << y unless y =~ ref }
        }
      end

      # _dic_.select( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+)
      def select(str)
        @src.each_with_object([]) { |src, lex|
          l = src[str] or next
          lex.concat(l)
          break lex unless @all
        }.tap { |lex| lex.sort!; lex.uniq! }
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
        select(str).tap { |l|
          if l.empty?
            affix_lexicals(affix, str).each { |a| select(a.form).each { |b|
              l << b if affix != :suffix || a.attr == b.attr
            } }
          end
        }
      end

      def affix_lexicals(affix, str)
        instance_variable_get("@#{affix}es").each_with_object([]) { |(r, e, t), l|
          l << Lexical.new("#{$`}#{e == '*' ? '' : e}#{$'}", t) if str =~ r
        }
      end

    end

  end

end
