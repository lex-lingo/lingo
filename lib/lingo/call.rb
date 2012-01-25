# encoding: utf-8

class Lingo

  class Call < self

    def initialize(args = [])
      super(args, StringIO.new, StringIO.new, StringIO.new)
    end

    def call
      invite

      if block_given?
        begin
          yield self
        ensure
          reset
        end
      else
        self
      end
    end

    def talk(str)
      config.stdin.reopen(str)

      start

      %w[stdout stderr].flat_map { |key|
        io = config.send(key).tap(&:rewind)
        io.readlines.each(&:chomp!).tap {
          io.truncate(0)
          io.rewind
        }
      }.tap { |res|
        if block_given?
          res.map!(&Proc.new)
        else
          res.sort!
          res.uniq!
        end
      }
    end

  end

end
