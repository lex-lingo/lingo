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

require_relative 'source/keyvalue'
require_relative 'source/multikey'
require_relative 'source/multivalue'
require_relative 'source/singleword'
require_relative 'source/wordclass'

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

      # Define printable characters for tokenizer for UTF-8 encoding
      UTF8_DIGIT  = '[0-9]'
      # Define Basic Latin printable characters for UTF-8 encoding from U+0000 to U+007f
      UTF8_BASLAT = '[A-Za-z]'
      # Define Latin-1 Supplement printable characters for UTF-8 encoding from U+0080 to U+00ff
      UTF8_LAT1SP = '[\xc3\x80-\xc3\x96\xc3\x98-\xc3\xb6\xc3\xb8-\xc3\xbf]'
      # Define Latin Extended-A printable characters for UTF-8 encoding from U+0100 to U+017f
      UTF8_LATEXA = '[\xc4\x80-\xc4\xbf\xc5\x80-\xc5\xbf]'
      # Define Latin Extended-B printable characters for UTF-8 encoding from U+0180 to U+024f
      UTF8_LATEXB = '[\xc6\x80-\xc6\xbf\xc7\x80-\xc7\xbf\xc8\x80-\xc8\xbf\xc9\x80-\xc9\x8f]'
      # Define IPA Extension printable characters for UTF-8 encoding from U+024f to U+02af
      UTF8_IPAEXT = '[\xc9\xa0-\xc9\xbf\xca\xa0-\xca\xaf]'
      # Collect all UTF-8 printable characters in Unicode range U+0000 to U+02af
      UTF8_CHAR   = "#{UTF8_DIGIT}|#{UTF8_BASLAT}|#{UTF8_LAT1SP}|#{UTF8_LATEXA}|#{UTF8_LATEXB}|#{UTF8_IPAEXT}"

      PRINTABLE_CHAR = "#{UTF8_CHAR}|[<>-]"

      def self.get(name, *args)
        const_get(name.capitalize).new(*args)
      end

      attr_reader :position

      def initialize(id, lingo)
        @config = lingo.database_config(id)

        source_file = Lingo.find(:dict, name = @config['name'])
        reject_file = begin
          Lingo.find(:store, source_file) << '.rev'
        rescue NoWritableStoreError
        end

        @pn_source = Pathname.new(source_file)
        @pn_reject = Pathname.new(reject_file) if reject_file

        raise SourceFileNotFoundError.new(name, id) unless @pn_source.exist?

        @wordclass = @config.fetch('def-wc', '?').downcase
        @separator = @config['separator']

        @legal_word = '(?:' + PRINTABLE_CHAR + '|[' + Regexp.escape('- /&()[].,') + '])+'  # TODO: v1.60 - ',' bei Source zulassen; in const.rb einbauen
        @line_pattern = Regexp.new('^'+@legal_word+'$')

        @position = 0
      end

      def size
        @pn_source.size
      end

      def each
        reject_file = @pn_reject.open('w', encoding: ENC) if @pn_reject

        @pn_source.each_line($/, encoding: ENC) { |line|
          @position += length = line.bytesize

          next if line =~ /\A\s*#/ || line.strip.empty?

          line.chomp!
          line.downcase!

          if length < 4096 && line =~ @line_pattern
            yield convert_line(line, $1, $2)
          else
            reject_file.puts(line) if reject_file
          end
        }

        self
      ensure
        if reject_file
          reject_file.close
          @pn_reject.delete if @pn_reject.size == 0
        end
      end

      def set(db, key, val)
        db[key] = val
      end

    end

  end

end
