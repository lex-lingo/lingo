# encoding: utf-8

class Lingo

  class Database

    class Source

      # Abgeleitet von Source behandelt die Klasse Dateien mit dem Format <tt>SingleWord</tt>.
      # Eine Zeile <tt>"Fachbegriff\n"</tt> wird gewandelt in <tt>[ 'fachbegriff', ['#s'] ]</tt>.
      # Die Wortklasse kann über den Parameter <tt>def-wc</tt> beeinflusst werden.

      class Singleword < self

        def initialize(id, lingo)
          super

          @wc     = @config.fetch('def-wc',     's').downcase
          @mul_wc = @config.fetch('def-mul-wc', @wc).downcase

          @line_pattern = %r{^(#{@legal_word})$}
        end

        private

        def convert_line(line, key, val)
          [key = key.strip, %W[##{key =~ /\s/ ? @mul_wc : @wc}]]
        end

      end

    end

  end

end
