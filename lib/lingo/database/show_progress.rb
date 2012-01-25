# encoding: utf-8

class Lingo

  class Database

    class ShowProgress

      def initialize(msg, active = true, out = $stderr)
        @active, @out, format = active, out, ' [%3d%%]'

        # To get the length of the formatted string we have
        # to actually substitute the placeholder.
        length = (format % 0).length

        # Now we know how far to "go back" to
        # overwrite the formatted string...
        back = "\b" * length

        @format = format       + back
        @clear  = ' ' * length + back

        print msg, ': '
      end

      def start(msg, max)
        @ratio, @count, @next_step = max / 100.0, 0, 0
        print msg, ' '
        step
      end

      def stop(msg)
        print @clear
        print msg, "\n"
      end

      def tick(value)
        @count = value
        step if @count >= @next_step
      end

      private

      def step
        percent = @count / @ratio
        @next_step = (percent + 1) * @ratio

        print @format % percent
      end

      def print(*args)
        @out.print(*args) if @active
      end

    end

  end

end
