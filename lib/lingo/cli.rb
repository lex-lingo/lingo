require 'nuggets/util/cli'

class Lingo

  class CLI < ::Util::CLI

    class << self

      def defaults
        super.merge(
          config:   'lingo.cfg',
          language: 'de',
          status:   false,
          perfmon:  false
        )
      end

    end

    attr_reader :files

    def run(arguments)
      @files = arguments
    end

    private

    def load_config(*)
      @config = {}
    end

    def opts(opts)
      opts.on('-c', '--config YAML', "Config file [Default: #{defaults[:config]}#{' (currently not present)' unless File.readable?(defaults[:config])}]") { |config|
        options[:config] = config
      }

      opts.separator ''

      opts.on('-l', '--language LANG', "Language for processing [Default: #{defaults[:language]}]") { |language|
        options[:language] = language
      }

      opts.separator ''

      opts.on('-s', '--status', 'Print status information after processing') {
        options[:status] = true
      }

      opts.on('-p', '--perfmon', 'Print performance details after processing') {
        options[:perfmon] = true
      }

      opts.separator ''

      opts.on('-L', '--log FILE', 'Log file to print debug and status information to') { |log|
        options[:log] = @stderr.reopen(File.open(log, 'a+', encoding: ENC))
      }
    end

  end

end
