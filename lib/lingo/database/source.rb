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

require_relative 'source/key_value'
require_relative 'source/multi_key'
require_relative 'source/multi_value'
require_relative 'source/single_word'
require_relative 'source/word_class'

class Lingo

  class Database

    # Die Klasse Source stellt eine einheitliche Schnittstelle auf die unterschiedlichen Formate
    # von Wörterbuch-Quelldateien bereit. Die Identifizierung der Quelldatei erfolgt über die ID
    # der Datei, so wie sie in der Sprachkonfigurationsdatei <tt>de.lang</tt> unter
    # <tt>language/dictionary/databases</tt> hinterlegt ist.
    #
    # Die Verarbeitung der Wörterbücher erfolgt mittels des Iterators <b>each</b>, der für jede
    # Zeile der Quelldatei ein Array bereitstellt in der Form <tt>[ key, [val1, val2, ...] ]</tt>.
    #
    # Nicht korrekt erkannte Zeilen werden abgewiesen und in eine Revoke-Datei gespeichert, die
    # an der Dateiendung <tt>.rev</tt> zu erkennen ist.

    class Source

      def self.get(name, *args)
        Lingo.get_const(name, self).new(*args)
      end

      attr_reader :pos

      def initialize(id, lingo, def_wc_default = nil)
        @config = lingo.database_config(id)

        source_file = Lingo.find(:dict, name = @config['name'], relax: true)

        reject_file = begin
          Lingo.find(:store, source_file) << '.rev'
        rescue NoWritableStoreError, SourceFileNotFoundError
        end

        @src = Pathname.new(source_file)
        @rej = Pathname.new(reject_file) if reject_file

        raise SourceFileNotFoundError.new(name, id) unless @src.exist?

        @def = @config.fetch('def-wc', def_wc_default)
        @def = @def.downcase if @def
        @sep = @config['separator']

        @wrd = "(?:#{Language::Char::ANY})+"
        @pat = /^#{@wrd}$/

        @pos = @rej_cnt = 0
      end

      def size
        @src.size
      end

      def each
        reject_file = @rej.open('w', encoding: ENC) if @rej

        @src.each_line($/, encoding: ENC) { |line|
          @pos += length = line.bytesize

          line.strip!
          next if line.empty? || line.start_with?('#')

          line.chomp!
          line.replace(Unicode.downcase(line))

          if length < 4096 && line =~ @pat
            yield convert_line(line, $1, $2)
          else
            @rej_cnt += 1
            reject_file.puts(line) if reject_file
          end
        }

        self
      ensure
        if reject_file
          reject_file.close
          @rej.delete if @rej.size == 0
        end
      end

      def set(db, key, val)
        db[key] = val
      end

      def rejected
        [@rej_cnt, @rej]
      end

    end

  end

end
