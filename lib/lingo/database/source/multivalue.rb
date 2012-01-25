# encoding: utf-8

class Lingo

  class Database

    class Source

      # Abgeleitet von Source behandelt die Klasse Dateien mit dem Format <tt>MultiValue</tt>.
      # Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ nil, ['triumph', 'sieg', 'erfolg'] ]</tt>.
      # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

      class Multivalue < self

        def initialize(id, lingo)
          super

          @separator = @config.fetch('separator', ';')
          @line_pattern = Regexp.new('^' + @legal_word + '(?:' + Regexp.escape(@separator) + @legal_word + ')*$')
        end

        private

        def convert_line(line, key, val)
          [nil, line.split(@separator).map { |value| value.strip }]
        end

      end

    end

  end

end
