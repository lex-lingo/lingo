# encoding: utf-8

class Lingo

  class Attendee

    class Formatter < Textwriter

      protected

      def init
        super

        @ext    = get_key('ext', '-')
        @format = get_key('format', '%s')
        @map    = get_key('map', Hash.new { |h, k| h[k] = k })

        @no_puts = true
      end

      def process(obj)
        if obj.is_a?(Word) || obj.is_a?(Token)
          str = obj.form

          if obj.respond_to?(:lexicals)
            lex = obj.lexicals.first  # TODO
            att = @map[lex.attr] if lex
            str = @format % [str, lex.form, att] if att
          end
        else
          str = obj.to_s
        end

        @lir ? @lir_rec_buf << str : @file.print(str)
      end

    end

  end

end
