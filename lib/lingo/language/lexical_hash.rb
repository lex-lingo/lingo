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
