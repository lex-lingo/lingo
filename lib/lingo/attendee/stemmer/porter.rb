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

  class Attendee

    class Stemmer

      module Porter

        extend self

        # Rules for Porter-Stemmer, based on:
        #
        #               An algorithm for suffix stripping
        #
        #                            M.F. Porter
        #                               1980
        #
        # Originally published in Program, 14 no. 3, pp 130-137, July 1980.
        # (A few typos have been corrected.)
        #
        # http://tartarus.org/~martin/PorterStemmer/def.txt
        #
        # -------------------------------------------------------------------
        #
        # 2. THE ALGORITHM
        #
        # To present the suffix stripping algorithm in its entirety we will
        # need a few definitions.
        #
        # A _consonant_ in a word is a letter other than A, E, I, O or U,
        # and other than Y preceded by a consonant. (The fact that the term
        # `consonant' is defined to some extent in terms of itself does not
        # make it ambiguous.) So in TOY the consonants are T and Y, and in
        # SYZYGY they are S, Z and G. If a letter is not a consonant it is
        # a _vowel_.
        #
        # A consonant will be denoted by c, a vowel by v. A list ccc... of
        # length greater than 0 will be denoted by C, and a list vvv... of
        # length greater than 0 will be denoted by V. Any word, or part of
        # a word, therefore has one of the four forms:
        #
        #     CVCV ... C
        #     CVCV ... V
        #     VCVC ... C
        #     VCVC ... V
        #
        # These may all be represented by the single form
        #
        #     [C]VCVC ... [V]
        #
        # where the square brackets denote arbitrary presence of their
        # contents. Using (VC){m} to denote VC repeated m times, this
        # may again be written as
        #
        #     [C](VC){m}[V].
        #
        # m will be called the _measure_ of any word or word part when
        # represented in this form. The case m = 0 covers the null word.
        # Here are some examples:
        #
        #     m=0    TR,  EE,  TREE,  Y,  BY.
        #     m=1    TROUBLE,  OATS,  TREES,  IVY.
        #     m=2    TROUBLES,  PRIVATE,  OATEN,  ORRERY.
        #
        # The _rules_ for removing a suffix will be given in the form
        #
        #     (condition) S1 -> S2
        #
        # This means that if a word ends with the suffix S1, and the stem
        # before S1 satisfies the given condition, S1 is replaced by S2.
        # The condition is usually given in terms of m, e.g.
        #
        #     (m > 1) EMENT ->
        #
        # Here S1 is `EMENT' and S2 is null. This would map REPLACEMENT to
        # REPLAC, since REPLAC is a word part for which m = 2.
        #
        # The `condition' part may also contain the following:
        #
        # *S  - the stem ends with S (and similarly for the other letters).
        #
        # *v* - the stem contains a vowel.
        #
        # *d  - the stem ends with a double consonant (e.g. -TT, -SS).
        #
        # *o  - the stem ends cvc, where the second c is not W, X or Y (e.g.
        #        -WIL, -HOP).
        #
        # And the condition part may also contain expressions with _and_,
        # _or_ and _not_, so that
        #
        #     (m>1 and (*S or *T))
        #
        # tests for a stem with m>1 ending in S or T, while
        #
        #     (*d and not (*L or *S or *Z))
        #
        # tests for a stem ending with a double consonant other than L, S
        # or Z. Elaborate conditions like this are required only rarely.
        #
        # In a set of rules written beneath each other, only one is obeyed,
        # and this will be the one with the longest matching S1 for the
        # given word. For example, with
        #
        #     SSES -> SS
        #     IES  -> I
        #     SS   -> SS
        #     S    ->
        #
        # (here the conditions are all null) CARESSES maps to CARESS since
        # SSES is the longest match for S1. Equally CARESS maps to CARESS
        # (S1=`SS') and CARES to CARE (S1=`S').
        #
        # In the rules below, examples of their application, successful or
        # otherwise, are given on the right in lower case. The algorithm
        # now follows: see RULES.
        #
        # The algorithm is careful not to remove a suffix when the stem is
        # too short, the length of the stem being given by its measure, m.
        # There is no linguistic basis for this approach. It was merely
        # observed that m could be used quite effectively to help decide
        # whether or not it was wise to take off a suffix.
        #
        # -------------------------------------------------------------------

        #

        RULES = {
          # Step 1a
          S100: [
            'SSES -> SS',  # caresses -> caress
            'IES  -> I',   # ponies   -> poni, ties -> ti
            'SS   -> SS',  # caress   -> caress
            'S    -> '     # cats     -> cat
          ],

          # Step 1b
          S110: [
            '(m>0) EED -> EE goto(S120)',  # agreed    ->  agree,   feed -> feed
            '(*v*) ED  ->    goto(S111)',  # plastered ->  plaster, bled -> bled
            '(*v*) ING ->    goto(S111)',  # motoring  ->  motor,   sing -> sing
            'goto(S120)'
          ],

          # If the second or third of the rules in Step 1b is successful,
          # the following is done:
          S111: [
            'AT -> ATE',                            # conflat(ed) -> conflate
            'BL -> BLE',                            # troubl(ed)  -> trouble
            'IZ -> IZE',                            # siz(ed)     -> size
            '(*d and not (*L or *S or *Z)) -> -1',  # hopp(ing)   -> hop
                                                    # tann(ed)    -> tan
                                                    # fall(ing)   -> fall
                                                    # hiss(ing)   -> hiss
                                                    # fizz(ed)    -> fizz
            '(m=1 and *o) -> E'                     # fail(ing)   -> fail
                                                    # fil(ing)    -> file
          ],

          # The rule to map to a single letter causes the removal of one of
          # the double letter pair. The -E is put back on -AT, -BL and -IZ,
          # so that the suffixes -ATE, -BLE and -IZE can be recognised later.
          # This E may be removed in step 4.

          # Step 1c
          S120: [
            '(*v*) Y -> I'  # happy -> happi, sky -> sky
          ],

          # Step 1 deals with plurals and past participles. The subsequent
          # steps are much more straightforward.

          # Step 2
          S200: [
            '(m>0) ATIONAL -> ATE',   # relational     -> relate
            '(m>0) TIONAL  -> TION',  # conditional    -> condition, rational -> rational
            '(m>0) ENCI    -> ENCE',  # valenci        -> valence
            '(m>0) ANCI    -> ANCE',  # hesitanci      -> hesitance
            '(m>0) IZER    -> IZE',   # digitizer      -> digitize
            '(m>0) ABLI    -> ABLE',  # conformabli    -> conformable
            '(m>0) ALLI    -> AL',    # radicalli      -> radical
            '(m>0) ENTLI   -> ENT',   # differentli    -> different
            '(m>0) ELI     -> E',     # vileli         -> vile
            '(m>0) OUSLI   -> OUS',   # analogousli    -> analogous
            '(m>0) IZATION -> IZE',   # vietnamization -> vietnamize
            '(m>0) ATION   -> ATE',   # predication    -> predicate
            '(m>0) ATOR    -> ATE',   # operator       -> operate
            '(m>0) ALISM   -> AL',    # feudalism      -> feudal
            '(m>0) IVENESS -> IVE',   # decisiveness   -> decisive
            '(m>0) FULNESS -> FUL',   # hopefulness    -> hopeful
            '(m>0) OUSNESS -> OUS',   # callousness    -> callous
            '(m>0) ALITI   -> AL',    # formaliti      -> formal
            '(m>0) IVITI   -> IVE',   # sensitiviti    -> sensitive
            '(m>0) BILITI  -> BLE'    # sensibiliti    -> sensible
          ],

          # The test for the string S1 can be made fast by doing a program
          # switch on the penultimate letter of the word being tested. This
          # gives a fairly even breakdown of the possible values of the
          # string S1. It will be seen in fact that the S1-strings in step 2
          # are presented here in the alphabetical order of their penultimate
          # letter. Similar techniques may be applied in the other steps.

          # Step 3
          S300: [
            '(m>0) ICATE -> IC',  # triplicate  -> triplic
            '(m>0) ATIVE -> ',    # formative   -> form
            '(m>0) ALIZE -> AL',  # formalize   -> formal
            '(m>0) ICITI -> IC',  # electriciti -> electric
            '(m>0) ICAL  -> IC',  # electrical  -> electric
            '(m>0) FUL   -> ',    # hopeful     -> hope
            '(m>0) NESS  -> '     # goodness    -> good
          ],

          # Step 4
          S400: [
            '(m>1) AL    -> ',               # revival     -> reviv
            '(m>1) ANCE  -> ',               # allowance   -> allow
            '(m>1) ENCE  -> ',               # inference   -> infer
            '(m>1) ER    -> ',               # airliner    -> airlin
            '(m>1) IC    -> ',               # gyroscopic  -> gyroscop
            '(m>1) ABLE  -> ',               # adjustable  -> adjust
            '(m>1) IBLE  -> ',               # defensible  -> defens
            '(m>1) ANT   -> ',               # irritant    -> irrit
            '(m>1) EMENT -> ',               # replacement -> replac
            '(m>1) MENT  -> ',               # adjustment  -> adjust
            '(m>1) ENT   -> ',               # dependent   -> depend
            '(m>1 and (*S or *T)) ION -> ',  # adoption    -> adopt
            '(m>1) OU    -> ',               # homologou   -> homolog
            '(m>1) ISM   -> ',               # communism   -> commun
            '(m>1) ATE   -> ',               # activate    -> activ
            '(m>1) ITI   -> ',               # angulariti  -> angular
            '(m>1) OUS   -> ',               # homologous  -> homolog
            '(m>1) IVE   -> ',               # effective   -> effect
            '(m>1) IZE   -> '                # bowdlerize  -> bowdler
          ],

          # The suffixes are now removed. All that remains is a little
          # tidying up.

          # Step 5a
          S500: [
            '(m>1) E -> ',            # probate -> probat, rate -> rate
            '(m=1 and not *o) E -> '  # cease   -> ceas
          ],

          # Step 5b
          S510: [
            '(m > 1 and *d and *L) -> -1'  # controll -> control, roll -> roll
          ]
        }

        GOTO_RE = %r{^#{goto_re = %r{\s*goto\((\S+)\)}}$}

        RULE_RE = %r{^(\(.+\))?\s*(\S*)\s*->\s*(\S*?)(?:#{goto_re})?\s*$}

        def stem(word, found = false)
          goto, conv = nil, lambda { |s, h| h.each { |q, r| s.gsub!(q, r.to_s) } }

          RULES.each { |key, rules|
            next if goto && goto != key.to_s

            rules.each { |rule|
              case rule
                when RULE_RE
                  cond, repl, goto = $1, $3, $4
                  stem = word[/(.+)#{Unicode.downcase($2)}$/, 1] or next
                when GOTO_RE
                  goto = $1
                  break
              end

              conv[shad = stem.dup,
                /[^aeiouy]/ => 'c',
                /[aeiou]/   => 'v',
                /cy/        => 'cv',
                /y/         => 'c'
              ]

              if cond
                conv[cond,
                  'm'   => shad.scan(/vc/).size,
                  '*v*' => shad.include?('v'),
                  '*d'  => shad.end_with?('c') && (last = stem[-1]) == stem[-2],
                  '*o'  => shad.end_with?('cvc') && !'wxy'.include?(last),
                  'and' => '&&',
                  'or'  => '||',
                  'not' => '!',
                  '='   => '=='
                ]

                last.upcase! if last
                cond.gsub!(/\*(\w)/) { last == $1 }

                next unless eval(cond)
              end

              found, word = true, begin
                stem[0...Integer(repl)]
              rescue ArgumentError
                stem << Unicode.downcase(repl)
              end

              break
            }
          }

          word if found
        end

      end

    end

  end

end
