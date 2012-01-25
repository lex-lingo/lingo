# encoding: utf-8

class Lingo

  module Language

    # Die Klasse Grammar beinhaltet grammatikalische Spezialitäten einer Sprache. Derzeit findet die
    # Kompositumerkennung hier ihren Platz, die mit der Methode find_compositum aufgerufen werden kann.
    # Die Klasse Grammar wird genau wie ein Dictionary initialisiert. Das bei der Initialisierung angegebene Wörterbuch ist Grundlage
    # für die Erkennung der Kompositumteile.

    class Grammar

      include Cachable
      include Reportable

      # initialize(config, dictionary_config) -> _Grammar_
      # config = Attendee-spezifische Parameter
      # dictionary_config = Datenbankkonfiguration aus de.lang
      def initialize(config, lingo)
        init_reportable
        init_cachable

        @dictionary = Dictionary.new(config, lingo)

        # Sprachspezifische Einstellungen für Kompositumverarbeitung laden (die nachfolgenden Werte können in der
        # Konfigurationsdatei de.lang nach belieben angepasst werden)
        comp = lingo.dictionary_config['compositum']

        # Ein Wort muss mindestens 8 Zeichen lang sein, damit überhaupt eine Prüfung stattfindet.
        @comp_min_word_size = (comp['min-word-size'] || '8').to_i

        # Die durchschnittliche Länge der Kompositum-Wortteile muss mindestens 4 Zeichen lang sein, sonst ist es kein
        # gültiges Kompositum.
        @comp_min_avg_part_size = (comp['min-avg-part-size'] || '4').to_i

        # Der kürzeste Kompositum-Wortteil muss mindestens 1 Zeichen lang sein
        @comp_min_part_size = (comp['min-part-size'] || '1').to_i

        # Ein Kompositum darf aus höchstens 4 Wortteilen bestehen
        @comp_max_parts = (comp['max-parts'] || '4').to_i

        # Die Wortklasse eines Kompositum-Wortteils kann separat gekennzeichnet werden, um sie von Wortklassen normaler Wörter
        # unterscheiden zu können z.B. Hausmeister => ['haus/s', 'meister/s'] oder Hausmeister => ['haus/s+', 'meister/s+'] mit
        # append-wordclass = '+'
        @append_wc = comp.fetch( 'append-wordclass', '' )

        # Bestimmte Sequenzen können als ungültige Komposita erkannt werden, z.B. ist ein Kompositum aus zwei Adjetiven kein
        # Kompositum, also skip-sequence = 'aa'
        @sequences = comp.fetch( 'skip-sequences', [] ).collect { |sq| sq.downcase }

        # Liste der Vorschläge für eine Zerlegung
        @suggestions = []
      end

      def close
        @dictionary.close
      end

      alias_method :report_grammar, :report

      def report
        rep = report_grammar
        rep.update(@dictionary.report)
        rep
      end

      # find_compositum(string) -> word wenn level=1
      # find_compositum(string) -> [lexicals, stats] wenn level!=1
      #
      # find_compositum arbeitet in verschiedenen Leveln, da die Methode auch rekursiv aufgerufen wird. Ein Level größer 1
      # entspricht daher einem rekursiven Aufruf
      def find_compositum(string, level=1, has_tail=false)
        # Prüfen, ob string bereits auf Kompositum getestet wurde. Wenn ja, dann Ergebnis des letztes Aufrufs zurück geben.
        key = string.downcase
        if level == 1 && hit?(key)
          inc('cache hits')
          return retrieve(key)
        end

        # Ergebnis vorbelegen
        comp = Word.new(string, Language::WA_UNKNOWN)

        # Validitätsprüfung: nur Strings mit Mindestlänge auf Kompositum prüfen
        if string.size <= @comp_min_word_size
          inc('String zu kurz')
          return (level==1) ? comp : [[],[],'']
        end

        # Kompositumerkennung initialisieren
        inc('Komposita geprüft')
        stats, lexis, seqs = permute_compositum(string.downcase, level, has_tail)

        if level==1
          # Auf Level 1 Kompositum zurück geben
          if lexis.size > 0 && is_valid?( string, stats, lexis, seqs )
            inc('Komposita erkannt')
            comp.attr = Language::WA_KOMPOSITUM
            comp.lexicals = lexis.collect do |lex|
              (lex.attr==Language::LA_KOMPOSITUM) ? lex : Lexical.new(lex.form, lex.attr+@append_wc)
            end
          end

          return store(key, comp)
        end

        # Validitätsprüfung
        if lexis.size > 0 && is_valid?(string, stats, lexis, seqs)
          [stats, lexis, seqs]
        else
          [[],[],'']
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

      # permute_string( _aString_ ) ->  [lexicals, stats, seqs]
      def permute_compositum(string, level, has_tail)
        @suggestions[level] = [] if @suggestions[level].nil?

        # Finde letzten Bindesstrich im Wort
        if string =~ /^(.+)-([^-]+)$/
          test_compositum($1, '-', $2, level, has_tail)
        else
          length = string.length

          # Wortteilungen testen
          1.upto(length - 1) do |p|
            # String teilen und testen
            fr_str, ba_str = string.slice(0...p), string.slice(p...length)
            stats, lexis, seqs = test_compositum(fr_str, '', ba_str, level, has_tail)

            unless lexis.empty?
              if lexis[-1].attr==Language::LA_TAKEITASIS
                # => halbes Kompositum
                @suggestions[level] << [stats, lexis, seqs]
              else
                # => ganzes Kompositum
                return [stats, lexis, seqs]
              end
            end
          end

          # alle Wortteilungen durchprobiert und noch immer kein definitives Kompositum erkannt. Dann nehme besten Vorschlag.
          if @suggestions[level].empty?
            [[],[],'']
          else
            stats, lexis, seqs = @suggestions[level][0]
            @suggestions[level].clear
            [stats, lexis, seqs]
          end
        end
      end

      # test_compositum() ->  [stats, lexicals, seq]
      #
      # Testet einen definiert zerlegten String auf Kompositum
      def test_compositum(front_string, infix, back_string, level, has_tail)
        # Statistik merken für Validitätsprüfung
        stats = [front_string.size, back_string.size]
        seqs = ['?', '?']

        # zuerst hinteren Teil auflösen
        # 1. Möglichkeit:  Wort mit oder ohne Suffix
        back_lexicals = @dictionary.select_with_suffix(back_string)
        unless back_lexicals.empty?
          back_form = has_tail ? back_string : back_lexicals.sort[0].form
          seqs[1] = back_lexicals.sort[0].attr
        end

        # 2. Möglichkeit:  Wort mit oder ohne Infix, wenn es nicht der letzte Teil des Wortes ist
        if back_lexicals.empty? && has_tail
          back_lexicals = @dictionary.select_with_infix(back_string)
          unless back_lexicals.empty?
            back_form = back_string
            seqs[1] = back_lexicals.sort[0].attr
          end
        end

        # 3. Möglichkeit:  Selber ein Kompositum (nur im Bindestrich-Fall!)
        if back_lexicals.empty? && infix=='-'
          back_stats, back_lexicals, back_seqs = find_compositum(back_string, level+1, has_tail)
          unless back_lexicals.empty?
            back_form = back_lexicals.sort[0].form
            seqs[1] = back_seqs
            stats = stats[0..0] + back_stats
          end
        end

        # 4. Möglichkeit:  Take it as is [Nimm's, wie es ist] (nur im Bindestrich-Fall!)
        if back_lexicals.empty? && infix=='-'
          back_lexicals = [Lexical.new(back_string, Language::LA_TAKEITASIS)]
          back_form = back_string
          seqs[1] = back_lexicals.sort[0].attr
        end

        # wenn immer noch nicht erkannt, dann sofort zurück
        return [[],[],''] if back_lexicals.empty?

        # dann vorderen Teil auflösen
        #
        # 1. Möglichkeit:  Wort mit oder ohne Infix
        front_lexicals = @dictionary.select_with_infix(front_string)
        unless front_lexicals.empty?
          front_form = front_string
          seqs[0] = front_lexicals.sort[0].attr
        end

        # 2. Möglichkeit:  Selber ein Kompositum
        if front_lexicals.empty?
          front_stats, front_lexicals, front_seqs = find_compositum(front_string, level+1, true)
          unless front_lexicals.empty?
            front_form = front_lexicals.sort[0].form
            seqs[0] = front_seqs
            stats = front_stats + stats[1..-1]
          end
        end

        # 3. Möglichkeit:  Take it as is [Nimm's, wie es ist] (nur im Bindestrich-Fall!)
        if front_lexicals.empty? && infix=='-'
          front_lexicals = [Lexical.new(front_string, Language::LA_TAKEITASIS)]
          seqs[0] = front_lexicals.sort[0].attr
          front_form = front_string
        end

        # wenn immer noch nicht erkannt, dann sofort zurück
        return [[],[],''] if front_lexicals.empty?

        # Kompositum gefunden, Grundform bilden
        lexis = (front_lexicals + back_lexicals).collect { |lex|
          (lex.attr==Language::LA_KOMPOSITUM) ? nil : lex
        }.compact
        lexis << Lexical.new(front_form + infix + back_form, Language::LA_KOMPOSITUM)

        [stats, lexis.sort, seqs.join ]
      end

    end

  end

end
