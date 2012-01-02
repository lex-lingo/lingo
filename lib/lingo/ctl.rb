require 'optparse'
require 'fileutils'

class Lingo

  module Ctl

    extend self

    PROG, VERSION, OPTWIDTH = $0, '0.0.1', 18
    PROGNAME, OPTIONS = File.basename(PROG), {}

    COMMANDS, ALIASES = {}, Hash.new { |_, k|
      COMMANDS.has_key?(k) ? k : 'usage'
    }

    { config: %w[configuration],
      lang:   %w[language],
      dict:   %w[dictionary dictionaries],
      store:  %w[store] }.each { |what, (sing, plur)|
      COMMANDS["list#{what}"] = [
        "List available #{plur || "#{sing}s"}",  'Arguments: [name...]'
      ] if what != :store
      COMMANDS["find#{what}"] = [
        "Find #{sing} in Lingo search path",     'Arguments: name'
      ]
      COMMANDS["copy#{what}"] = [
        "Copy #{sing} to local Lingo directory", 'Arguments: name'
      ] if what != :store

      %w[list find copy].each { |method|
        next unless COMMANDS.has_key?(name = "#{method}#{what}")
        class_eval %Q{def do_#{name}; #{method}(:#{what}); end}
        ALIASES["#{method[0]}#{what[0]}"] = name
      }
    }

    { path:    'Print search path for dictionaries and configurations',
      help:    'Print help for available commands',
      version: 'Print Lingo version number' }.each { |what, description|
      COMMANDS[name = what.to_s] = description; ALIASES[name[0]] = name
    }

    USAGE = <<EOT
Usage: #{PROG} <command> [arguments] [options]
       #{PROG} [-h|--help] [--version]
EOT

    def do
      parse_options
      send("do_#{ALIASES[ARGV.shift]}")
    end

    private

    def list(what)
      names = Regexp.union(*ARGV.empty? ? '' : ARGV)

      Lingo.list(what, path: path_for_scope).each { |file|
        puts file if File.basename(file) =~ names
      }
    end

    def find(what, doit = true)
      name = ARGV.shift or do_usage('Required argument `name\' missing.')
      no_args

      file = Lingo.find(what, name, path: path_for_scope, &method(:do_usage))
      doit ? puts(file) : file
    end

    def copy(what)
      do_usage('Source and target are the same.') if OPTIONS[:scope] == :local

      source = find(what, false)
      target = File.join(path_for_scope(:local), Lingo.basepath(what, source))

      do_usage('Source and target are the same.') if source == target

      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(source, target, verbose: true)
    end

    def do_path
      no_args
      puts path_for_scope || PATH
    end

    def do_help(opts = nil)
      no_args

      msg = opts ? [opts, 'Commands:'] : []

      aliases = Hash.new { |h, k| h[k] = [] }
      ALIASES.each { |k, v| aliases[v] << k }

      COMMANDS.each { |c, (d, *e)|
        a = aliases[c]
        c = "#{c} (#{a.join(', ')})" unless a.empty?

        if opts
          msg << "    %-#{OPTWIDTH}s %s" % [c, d]
        else
          msg << "#{c}" << "  - #{d}"
          e.each { |i| msg <<  "  + #{i}" }
        end
      }

      abort msg.join("\n")
    end

    def do_version(doit = true)
      no_args

      msg = "Lingo v#{Lingo::VERSION}"
      doit ? puts(msg) : msg
    end

    def do_usage(msg = nil)
      abort "#{"#{PROGNAME}: #{msg}\n\n" if msg}#{USAGE}"
    end

    def parse_options
      OptionParser.new(USAGE, OPTWIDTH) { |opts|
        opts.separator ''
        opts.separator 'Scope options:'

        opts.on('--system', 'Restrict command to the system-wide Lingo directory') {
          OPTIONS[:scope] = :system
        }

        opts.on('--global', 'Restrict command to the user\'s personal Lingo directory') {
          OPTIONS[:scope] = :global
        }

        opts.on('--local', 'Restrict command to the local Lingo directory') {
          OPTIONS[:scope] = :local
        }

        opts.separator ''
        opts.separator 'Generic options:'

        opts.on('-h', '--help', 'Print this help message and exit') {
          do_help(opts)
        }

        opts.on('--version', 'Print program version and exit') {
          abort "#{PROGNAME} v#{VERSION} (#{do_version(false)})"
        }
      }.parse!
    end

    def path_for_scope(scope = OPTIONS[:scope])
      case scope
        when :system then [BASE]
        when :global then [HOME]
        when :local  then [CURR]
        when nil
        else do_usage("Invalid scope `#{scope.inspect}'.")
      end
    end

    def no_args
      do_usage('Too many arguments.') unless ARGV.empty?
    end

  end

  def self.ctl
    Ctl.do
  rescue => err
    raise if $VERBOSE
    abort "#{err.backtrace.first}: #{err} (#{err.class})"
  end

end
