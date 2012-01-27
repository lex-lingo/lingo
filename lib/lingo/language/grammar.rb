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

    # Die Klasse Grammar beinhaltet grammatikalische Spezialitäten einer Sprache. Derzeit findet die
    # Kompositumerkennung hier ihren Platz, die mit der Methode find_compositum aufgerufen werden kann.
    # Die Klasse Grammar wird genau wie ein Dictionary initialisiert. Das bei der Initialisierung angegebene Wörterbuch ist Grundlage
    # für die Erkennung der Kompositumteile.

    class Grammar

      include Cachable
      include Reportable

      HYPHEN_RE = %r{\A(.+)-([^-]+)\z}

      # initialize(config, dictionary_config) -> _Grammar_
      # config = Attendee-spezifische Parameter
      # dictionary_config = Datenbankkonfiguration aus de.lang
      def initialize(config, lingo)
        init_cachable
        init_reportable

        @dic, @suggestions = Dictionary.new(config, lingo), []

        cfg = lingo.dictionary_config['compositum']

        # Ein Wort muss mindestens 8 Zeichen lang sein, damit
        # überhaupt eine Prüfung stattfindet.
        @min_word_size = (cfg['min-word-size'] || 8).to_i

        # Die durchschnittliche Länge der Kompositum-Wortteile
        # muss mindestens 4 Zeichen lang sein, sonst ist es kein
        # gültiges Kompositum.
        @min_avg_part_size = (cfg['min-avg-part-size'] || 4).to_i

        # Der kürzeste Kompositum-Wortteil muss mindestens 1 Zeichen lang sein
        @min_part_size = (cfg['min-part-size'] || 1).to_i

        # Ein Kompositum darf aus höchstens 4 Wortteilen bestehen
        @max_parts = (cfg['max-parts'] || 4).to_i

        # Die Wortklasse eines Kompositum-Wortteils kann separat gekennzeichnet
        # werden, um sie von Wortklassen normaler Wörter unterscheiden zu
        # können z.B. Hausmeister => ['haus/s', 'meister/s'] oder Hausmeister
        # => ['haus/s+', 'meister/s+'] mit append-wordclass = '+'
        @append_wc = cfg.fetch('append-wordclass', '')

        # Bestimmte Sequenzen können als ungültige Komposita erkannt werden,
        # z.B. ist ein Kompositum aus zwei Adjetiven kein Kompositum, also
        # skip-sequence = 'aa'
        @sequences = cfg.fetch('skip-sequences', []).map(&:downcase)
      end

      def close
        @dic.close
      end

      def report
        super.update(@dic.report)
      end

      # find_compositum(str) -> word wenn level=1
      # find_compositum(str) -> [lex, sta] wenn level!=1
      #
      # find_compositum arbeitet in verschiedenen Leveln, da die Methode auch rekursiv aufgerufen wird. Ein Level größer 1
      # entspricht daher einem rekursiven Aufruf
      def find_compositum(str, level = 1, tail = false)
        key, top, empty = str.downcase, level == 1, [[], [], '']

        if top && hit?(key)
          inc('cache hits')
          return retrieve(key)
        end

        com = Word.new(str, WA_UNKNOWN)

        unless str.length > @min_word_size
          inc('String zu kurz')
          return top ? com : empty
        end

        inc('Komposita geprüft')

        res = permute_compositum(key, level, tail)
        val = !(lex = res.first).empty? && valid?(str, *res[1..-1])

        if top
          if val
            inc('Komposita erkannt')

            com.attr = WA_KOMPOSITUM
            com.lexicals = lex.map { |l|
              l.attr == LA_KOMPOSITUM ? l :
                Lexical.new(l.form, l.attr + @append_wc)
            }
          end

          store(key, com)
        else
          val ? res : empty
        end
      end

      # permute_compositum( _aString_ ) ->  [lex, sta, seq]
      def permute_compositum(str, level, tail)
        return test_compositum($1, '-', $2, level, tail) if str =~ HYPHEN_RE

        sug, len = @suggestions[level] ||= [], str.length

        1.upto(len - 1) { |i|
          res = test_compositum(str[0, i], '', str[i, len], level, tail)

          unless (lex = res.first).empty?
            return res unless lex.last.attr == LA_TAKEITASIS
            sug << res
          end
        }

        sug.empty? ? [[], [], ''] : sug.first.tap { sug.clear }
      end

      # test_compositum() ->  [lex, sta, seq]
      #
      # Testet einen definiert zerlegten String auf Kompositum
      def test_compositum(fstr, infix, bstr, level, tail)
        sta, seq, empty = [fstr.length, bstr.length], %w[? ?], [[], [], '']

        if !(blex = @dic.select_with_suffix(bstr)).sort!.empty?
          # 1. Word w/ suffix
          bform, seq[1] = tail ? bstr : blex.first.form, blex.first.attr
        elsif tail && !(blex = @dic.select_with_infix(bstr)).sort!.empty?
          # 2. Word w/ infix, unless tail part
          bform, seq[1] = bstr, blex.first.attr
        elsif infix == '-'
          blex, bsta, bseq = find_compositum(bstr, level + 1, tail)

          if !blex.sort!.empty?
            # 3. Compositum
            bform, seq[1], sta[1..-1] = blex.first.form, bseq, bsta
          else
            # 4. Take it as is
            blex = [Lexical.new(bform = bstr, seq[1] = LA_TAKEITASIS)]
          end
        else
          return empty
        end

        if !(flex = @dic.select_with_infix(fstr)).sort!.empty?
          # 1. Word w/ infix
          fform, seq[0] = fstr, flex.first.attr
        else
          flex, fsta, fseq = find_compositum(fstr, level + 1, true)

          if !flex.sort!.empty?
            # 2. Compositum
            fform, seq[0], sta[0..0] = flex.first.form, fseq, fsta
          elsif infix == '-'
            # 3. Take it as is
            flex = [Lexical.new(fform = fstr, seq[0] = LA_TAKEITASIS)]
          else
            return empty
          end
        end

        flex.concat(blex).delete_if { |l| l.attr == LA_KOMPOSITUM }.
          push(Lexical.new(fform + infix + bform, LA_KOMPOSITUM)).sort!

        [flex, sta, seq.join]
      end

      private

      def valid?(str, sta, seq)
        sta.size               <= @max_parts         &&
        sta.sort.first         >= @min_part_size     &&
        str.length / sta.size  >= @min_avg_part_size &&
        (@sequences.empty? || !@sequences.include?(seq))
      end

    end

  end

end
