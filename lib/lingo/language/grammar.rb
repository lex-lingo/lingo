# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2016 John Vorhauer, Jens Wille                           #
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

    #--
    # Die Klasse Grammar beinhaltet grammatikalische Spezialitäten einer Sprache. Derzeit findet die
    # Kompositumerkennung hier ihren Platz, die mit der Methode find_compound aufgerufen werden kann.
    # Die Klasse Grammar wird genau wie ein Dictionary initialisiert. Das bei der Initialisierung angegebene Wörterbuch ist Grundlage
    # für die Erkennung der Kompositumteile.
    #++

    class Grammar

      include ArrayUtils

      HYPHEN_RE = %r{\A(.+)-([^-]+)\z}

      DEFAULTS = {
        min_word_size: 8, min_avg_part_size: 4, min_part_size: 1, max_parts: 4
      }

      def self.open(*args)
        yield grammar = new(*args)
      ensure
        grammar.close if grammar
      end

      def initialize(config, lingo)
        @dic, @suggestions = Dictionary.new(config, lingo), []

        cfg = lingo.dictionary_config['compound']

        DEFAULTS.each { |k, v| instance_variable_set(
          "@#{k}", cfg.fetch(k.to_s.tr('_', '-'), v).to_i) }

        #--
        # Die Wortklasse eines Kompositum-Wortteils kann separat gekennzeichnet
        # werden, um sie von Wortklassen normaler Wörter unterscheiden zu
        # können z.B. Hausmeister => ['haus/s', 'meister/s'] oder Hausmeister
        # => ['haus/s+', 'meister/s+'] mit append-wordclass = '+'
        #++
        @append_wc = cfg.fetch('append-wordclass', '')

        #--
        # Bestimmte Sequenzen können als ungültige Komposita erkannt werden,
        # z.B. ist ein Kompositum aus zwei Adjetiven kein Kompositum, also
        # skip-sequence = 'aa'
        #++
        @sequences = cfg.fetch('skip-sequences', []).map! { |i| i.downcase }
      end

      def close
        @dic.close
      end

      def find_compound(str, level = 1, tail = false)
        level == 1 ? (@_compound ||= {})[str] ||=
          permute_compound(Word.new(str, WA_UNKNOWN), str, level, tail) :
          permute_compound([[], [], ''],              str, level, tail)
      end

      def find_compound_head(str)
        compound = find_compound(str)
        compound.head || compound if compound && !compound.unknown?
      end

      private

      def permute_compound(ret, str, level, tail)
        if (len = str.length) > @min_word_size
          str = Unicode.downcase(str)

          lex, sta, seq = res = if str =~ HYPHEN_RE
            test_compound($1, '-', $2, level, tail)
          else
            sug = @suggestions[level] ||= []

            catch(:res) {
              1.upto(len - 1) { |i|
                tst = test_compound(str[0, i], '', str[i, len], level, tail)

                unless (lex = tst.first).empty?
                  lex.last.attr == LA_TAKEITASIS ? sug << tst : throw(:res, tst)
                end
              }

              sug.empty? ? [[], [], ''] : sug.first.tap { sug.clear }
            }
          end

          level > 1 ? ret = res : ret.identify(lex.each { |l|
            l.attr += @append_wc unless l.attr == LA_COMPOUND
          }, WA_COMPOUND, seq) if !lex.empty? &&
            sta.size              <= @max_parts         &&
            sta.min               >= @min_part_size     &&
            str.length / sta.size >= @min_avg_part_size &&
            (@sequences.empty? || !@sequences.include?(seq))
        end

        ret
      end

      def test_compound(fstr, infix, bstr, level = 1, tail = false)
        sta, seq, empty = [fstr.length, bstr.length], %w[? ?], [[], [], '']

        if !(blex = @dic.select_with_suffix(bstr)).empty?
          # 1. Word w/ suffix
          bform, seq[1] = tail ? bstr : blex.first.form, blex.first.attr
        elsif tail && !(blex = @dic.select_with_infix(bstr)).empty?
          # 2. Word w/ infix, unless tail part
          bform, seq[1] = bstr, blex.first.attr
        elsif infix == '-'
          blex, bsta, bseq = find_compound(bstr, level + 1, tail)

          if !blex.empty?
            # 3. Compound
            bform, seq[1], sta[1..-1] = blex.first.form, bseq, bsta
          else
            # 4. Take it as is
            blex = [Lexical.new(bform = bstr, seq[1] = LA_TAKEITASIS)]
          end
        else
          return empty
        end

        if !(flex = @dic.select_with_infix(fstr)).empty?
          # 1. Word w/ infix
          fform, seq[0] = fstr, flex.first.attr
        else
          flex, fsta, fseq = find_compound(fstr, level + 1, true)

          if !flex.empty?
            # 2. Compound
            fform, seq[0], sta[0..0] = flex.first.form, fseq, fsta
          elsif infix == '-'
            # 3. Take it as is
            flex = [Lexical.new(fform = fstr, seq[0] = LA_TAKEITASIS)]
          else
            return empty
          end
        end

        forms = [[flex, fform], [blex, bform]].each { |ary|
          ary.shift.each { |lex| lex.src ||= ary.first }
        }

        flex.concat(blex).delete_if { |lex| lex.attr == LA_COMPOUND }

        [combinations(*forms).map { |front, back|
          Lexical.new(front + infix + back, LA_COMPOUND)
        }.concat(flex), sta, seq.join]
      end

    end

  end

end
