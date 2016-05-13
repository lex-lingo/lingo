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

require_relative 'source/key_value'
require_relative 'source/multi_key'
require_relative 'source/multi_value'
require_relative 'source/single_word'
require_relative 'source/word_class'

class Lingo

  class Database

    #--
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
    #++

    class Source

      LEXICAL_SEPARATOR = '#'.freeze

      DEFAULT_SEPARATOR = nil

      DEFAULT_DEF_WC = nil

      MAX_LENGTH = 4096

      class << self

        def from_id(id, lingo)
          from_config(lingo.database_config(id), id)
        end

        def from_config(config, id = nil)
          format = config.fetch('txt-format', 'key_value')
          Lingo.get_const(format, self).new(config['name'], config, id)
        end

        def lexicals(val, sep = LEXICAL_SEPARATOR, ref = KEY_REF_RE)
          val.map { |str|
            str =~ ref ? $1.to_i : begin
              k, *w = str.split(sep)
              Language::Lexical.new(k.strip, w)
            end
          }.uniq if val
        end

      end

      attr_reader :pos

      def initialize(name = nil, config = {}, id = nil)
        @config = config

        src_file = Lingo.find(:dict, name, relax: true) if name

        rej_file = begin
          Lingo.find(:store, src_file) << '.rev'
        rescue NoWritableStoreError, SourceFileNotFoundError
        end if id && src_file

        @src = Pathname.new(src_file) if src_file
        @rej = Pathname.new(rej_file) if rej_file

        raise id ? SourceFileNotFoundError.new(name, id) :
          FileNotFoundError.new(name) if name && !@src.exist?

        @sep = config.fetch('separator', self.class::DEFAULT_SEPARATOR)
        @def = config.fetch('def-wc', self.class::DEFAULT_DEF_WC)
        @def = @def.downcase if @def

        @wrd = "(?:#{Language::Char::ANY})+"
        @pat = /^#{@wrd}$/

        @pos = @rej_cnt = 0
      end

      def size
        @src.size
      end

      def each
        rej_file = @rej.open('w', encoding: ENCODING) if @rej

        @src.each_line($/, encoding: ENCODING) { |line|
          @pos += length = line.bytesize

          line.strip!
          next if line.empty? || line.start_with?('#')

          if length < MAX_LENGTH && line.replace(Unicode.downcase(line)) =~ @pat
            yield convert_line(line, $1, $2)
          else
            @rej_cnt += 1
            rej_file.puts(line) if rej_file
          end
        }

        self
      ensure
        if rej_file
          rej_file.close
          @rej.delete if @rej.size.zero?
        end
      end

      def each_lexical
        return enum_for(__method__) unless block_given?
        each { |key, val| yield key, self.class.lexicals(val) }
      end

      def set(db, key, val)
        db[key] = val
      end

      def rejected
        [@rej_cnt, @rej]
      end

      private

      def lexical(*args)
        args.join(LEXICAL_SEPARATOR)
      end

    end

  end

end
