# encoding: utf-8

class Lingo

  class Database

    class Source

      # Abgeleitet von Source behandelt die Klasse Dateien mit dem Format <tt>MultiKey</tt>.
      # Eine Zeile <tt>"Triumph;Sieg;Erfolg\n"</tt> wird gewandelt in <tt>[ 'triumph', ['sieg', 'erfolg'] ]</tt>.
      # Die Sonderbehandlung erfolgt in der Methode Database#convert, wo daraus Schlüssel-Werte-Paare in der Form
      # <tt>[ 'sieg', ['triumph'] ]</tt> und <tt>[ 'erfolg', ['triumph'] ]</tt> erzeugt werden.
      # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

      class Multikey < self

        def initialize(id, lingo)
          super

          @separator = @config.fetch('separator', ';')
          @line_pattern = Regexp.new('^' + @legal_word + '(?:' + Regexp.escape(@separator) + @legal_word + ')*$')
        end

        private

        def convert_line(line, key, val)
          values = line.split(@separator).map { |value| value.strip }
          [values[0], values[1..-1]]
        end

      end

    end

  end

end
