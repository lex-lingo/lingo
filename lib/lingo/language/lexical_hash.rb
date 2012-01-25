# encoding: utf-8

class Lingo

  module Language

    # Die Klasse LexicalHash ermöglicht den Zugriff auf die Lingodatenbanken. Im Gegensatz zur
    # Klasse Database, welche nur Strings als Ergebnis zurück gibt, wird hier als Ergebnis ein
    # Array von Lexical-Objekten zurück gegeben.

    class LexicalHash

      include Cachable
      include Reportable

      def initialize(id, lingo)
        init_reportable(id)
        init_cachable

        config = lingo.config['language/dictionary/databases/' + id]
        raise "No such data source `#{id}'" unless config

        @wordclass = config.fetch('def-wc', Language::LA_UNKNOWN)

        @source = Database.open(id, lingo)
      end

      def close
        @source.close
      end

      def [](key)
        inc('total requests')
        key = key.downcase

        if hit?(key)
          inc('cache hits')
          return retrieve(key)
        end

        inc('source reads')

        if record = @source[key]
          record = record.map { |str|
            case str
              when /^\*\d+$/           then str
              when /^#(.)$/            then Lexical.new(key, $1)
              when /^([^#]+?)\s*#(.)$/ then Lexical.new($1, $2)
              when /^([^#]+)$/         then Lexical.new($1, @wordclass)
              else                          str
            end
          }

          record.compact!
          record.sort!
          record.uniq!

          inc('data found')
        end

        store(key, record)
      end

    end

  end

end
