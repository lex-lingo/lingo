# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2014 John Vorhauer, Jens Wille                           #
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

      def self.open(*args)
        yield dictionary = new(*args)
      ensure
        dictionary.close if dictionary
      end

      def initialize(config, lingo)
        unless config.key?('source')
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
        (@_word ||= {})[str] ||=
          Word.new(str, WA_UNKNOWN).identify(select_with_suffix(str))
      end

      def find_synonyms(obj, syn = [], com = true)
        lex = obj.lexicals
        lex = [obj] if lex.empty? && obj.unknown?

        com &&= obj.attr == WA_COMPOUND

        lex.each { |l|
          select(l.form, syn) unless com &&
            l.attr != LA_COMPOUND || l.attr == LA_SYNONYM
        }

        syn
      end

      # _dic_.select( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+)
      def select(str, lex = [])
        @src.each { |src|
          lex.concat(src[str] || next)
          break unless @all
        }

        lex.empty? && block_given? ? yield(lex) : lex.uniq!
        lex
      end

      # _dic_.select_with_suffix( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+).
      # Sucht dabei auch Wörter, die um wortklassenspezifische Suffixe bereinigt wurden.
      def select_with_suffix(str)
        select(str) { |lex|
          each_affix(str) { |form, attr|
            unless (selected = select(form)).empty?
              if selected.first.attr == LA_COMPOUND
                lex.concat(selected) if selected.last.attr?(attr)
              else
                selected.each { |l| lex << l if l.attr?(attr) }
              end
            end
          }
        }
      end

      # _dic_.select_with_infix( _aString_ ) -> _ArrayOfLexicals_
      #
      # Sucht alle Wörterbücher durch und gibt den ersten Treffer zurück (+mode = first+), oder alle Treffer (+mode = all+).
      # Sucht dabei auch Wörter, die eine Fugung am Ende haben.
      def select_with_infix(str)
        select(str) { |lex|
          each_affix(str, :infix) { |form, _| select(form, lex) }
        }
      end

      def each_affix(str, affix = :suffix)
        instance_variable_get("@#{affix}es").each { |r, e, t|
          yield "#{$`}#{e == '*' ? '' : e}#{$'}", t if str =~ r
        }
      end

    end

  end

end
