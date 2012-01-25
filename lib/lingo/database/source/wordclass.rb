# encoding: utf-8

class Lingo

  class Database

    class Source

      # Abgeleitet von Source behandelt die Klasse Dateien mit dem Format <tt>WordClass</tt>.
      # Eine Zeile <tt>"essen,essen #v essen #o esse #s\n"</tt> wird gewandelt in <tt>[ 'essen', ['esse#s', 'essen#v', 'essen#o'] ]</tt>.
      # Der Trenner zwischen Schlüssel und Projektion kann über den Parameter <tt>separator</tt> geändert werden.

      class Wordclass < self

        def initialize(id, lingo)
          super

          @separator = @config.fetch('separator', ',')
          @line_pattern = Regexp.new('^(' + @legal_word + ')' + Regexp.escape(@separator) + '((?:' + @legal_word + '#\w)+)$')
        end

        private

        def convert_line(line, key, val)
          key, valstr = key.strip, val.strip
          val = valstr.gsub(/\s+#/, '#').scan(/\S.+?\s*#\w/)
          val = val.map do |str|
            str =~ /^(.+)#(.)/
            ($1 == key ? '' : $1) + '#' + $2
          end
          [key, val]
        end

      end

    end

  end

end
