# encoding: utf-8

class Lingo

  class Database

    class Source

      # Abgeleitet von Source behandelt die Klasse Dateien mit dem Format <tt>KeyValue</tt>.
      # Eine Zeile <tt>"Fachbegriff*Fachterminus\n"</tt> wird gewandelt in <tt>[ 'fachbegriff', ['fachterminus#s'] ]</tt>.
      # Die Wortklasse kann über den Parameter <tt>def-wc</tt> beeinflusst werden.
      # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

      class Keyvalue < self

        def initialize(id, lingo)
          super

          @separator = @config.fetch('separator', '*')
          @line_pattern = Regexp.new('^(' + @legal_word + ')' + Regexp.escape(@separator) + '(' + @legal_word + ')$')
        end

        private

        def convert_line(line, key, val)
          key, val = key.strip, val.strip
          val = '' if key == val
          val = [val + '#' + @wordclass]
          [key, val]
        end

      end

    end

  end

end
