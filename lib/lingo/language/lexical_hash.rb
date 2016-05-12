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
    # Die Klasse LexicalHash ermöglicht den Zugriff auf die Lingodatenbanken. Im Gegensatz zur
    # Klasse Database, welche nur Strings als Ergebnis zurück gibt, wird hier als Ergebnis ein
    # Array von Lexical-Objekten zurück gegeben.
    #++

    class LexicalHash

      def self.open(*args)
        yield lexical_hash = new(*args)
      ensure
        lexical_hash.close if lexical_hash
      end

      def initialize(id, lingo)
        @src = Database.open(id, lingo)
        @ref = Database::KEY_REF_RE
        @sep = Database::Source::LEXICAL_SEPARATOR
      end

      def close
        @src.close
      end

      def [](key)
        rec = @src[Unicode.downcase(key)] or return

        res = rec.map { |str|
          str =~ @ref ? $1.to_i : begin
            k, *w = str.split(@sep)
            Lexical.new(k.strip, w)
          end
        }

        res.uniq!
        res
      end

    end

  end

end
