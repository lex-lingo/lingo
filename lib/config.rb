# encoding: utf-8

#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005-2007 John Vorhauer
#  Copyright (C) 2007-2011 John Vorhauer, Jens Wille
#
#  This program is free software; you can redistribute it and/or modify it under
#  the terms of the GNU Affero General Public License as published by the Free
#  Software Foundation; either version 3 of the License, or (at your option)
#  any later version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
#  details.
#
#  You should have received a copy of the GNU Affero General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
#  For more information visit http://www.lex-lingo.de or contact me at
#  welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
#  Lex Lingo rules from here on

require 'yaml'

#  LingoConfig will hold the complete comfiguration information, which will
#  control lingos processing flow.
#  The complete configuration will hold three sets of information
#
#  1. Language specific configuration information (refer to @keys['language'])
#     ------------------------------------------------------------------------
#     LingoConfig will load the configuration file, i.e. de.lang
#     You can tell lingo to use a specific language definition file
#     by using the -l command line option follow by the language shortcut.
#     For example if you call 'ruby lingo.rb -l en <file_to_process>' lingo
#     will load the file en.lang. If you ommit the -l option, then lingo will
#     use the default value, which is documented in the lingo.opt file in the
#     language section, i.e.
#       language:
#         opt: '-l'
#         value:
#         default: de
#         comment: >
#           Set the language for processing, i.e. '-l en' for loading en.lang
#
#  2. Processing specific configuration information (refer to @keys['meeting'])
#     -------------------------------------------------------------------------
#     LingoConfig will load the configuration file lingo.cfg by default.
#     You can tell lingo to use an other configuration file
#     by using the -c command line option follow by the configuration name.
#     For example if you call 'ruby lingo.rb -c test <file_to_process>' lingo
#     will load the file test.cfg. If you ommit the -c option, then lingo will
#     use the default configuration, which is documented in the lingo.opt file
#     in the config section, i.e.
#       config:
#         opt: '-c'
#         value:
#         default: lingo.cfg
#         comment: >
#           Set the configuration for processing, i.e. '-c test' for loading test.cfg
#
#  3. Command line options (refer to @keys['cmdline'])
#     ------------------------------------------------
#     You can add any additional command line option to modify the flow of lingo.
#     Define a new section in lingo.opt and find the results in @keys['cmdline'].
#     For example, if you want to control the Decomposer with a command line option
#     to change the 'min-word-size' value, then just define a '-m' option in lingo.opt
#       minwordsize:
#         opt: '-m'
#         value:
#         default: 7
#         comment: >
#           Set the minimum word length for the Decomposer composition recognition.
#
#     Then modify in de.lang the part
#       compositum:
#         min-word-size: "7"
#     to
#       compositum:
#         min-word-size: "$(minwordsize)"
#     and your done.

class LingoConfig

  def initialize(prog = $0, cmdline = $*)
    @keys = {}

    @options = load_yaml_file(prog, '.opt')
    @keys['cmdline'] = parse_cmdline(cmdline, @options)

    usage('') if @keys['cmdline']['usage']

    { 'language' => '.lang', 'config' => '.cfg' }.each { |key, ext|
      @keys.update(load_yaml_file(@keys['cmdline'][key], ext))
    }

    %w[language meeting].each { |key| patch_keys(@keys[key]) }
  end

  def [](key)
    raise 'Keine Konfiguration geladen!' unless @keys
    key_to_nodes(key).inject(@keys) { |value, node| value[node] }
  end

  def []=(key, value)
    nodes = key_to_nodes(key); node = nodes.pop
    (self[nodes_to_key(nodes)] ||= {})[node] = value
  end

  private

  def key_to_nodes(key)
    key.downcase.split('/')
  end

  def nodes_to_key(nodes)
    nodes.join('/')
  end

  def parse_cmdline(cmdline, hash)
    keys, non_hyphen_opt = {}, nil

    hash['command-line-options'].each { |opt, att|
      unless att['opt']
        non_hyphen_opt = opt
        next
      end

      unless idx = cmdline.index(att['opt'])
        keys[opt] = att['default'] || false
      else
        val = cmdline.delete_at(idx)

        keys[opt] = if att.has_key?('value')
          idx += 1

          if cmdline.size < idx || cmdline[idx][0] == ?-
            usage("Option #{opt} verlangt die Angabe eines Wertes!")
          else
            val
          end
        else
          true
        end
      end

    } if hash

    opts = cmdline.map { |opt| opt if opt[0] == ?- }.compact.join('|')
    usage("Unbekannte Optionen (#{opts})!") unless opts.empty?

    keys[non_hyphen_opt] = cmdline.join('|')

    keys
  end

  def load_yaml_file(name, ext)
    file = name.sub(/(?:\.[^.]+)?\z/, ext)
    file = File.join(File.dirname(__FILE__), '..', file) unless name.include?('/')

    usage("Datei #{file} nicht vorhanden") unless File.readable?(file)

    File.open(file, :encoding => ENC) { |f| YAML.load(f) }
  end

  def patch_keys(cont)
    case cont
      when Array, is_hash = Hash
        cont.send(is_hash ? :each_value : :each) { |val|
          case val
            when nil
              # ignore
            when String
              val.gsub!(/\$\((.+?)\)/) { @keys['cmdline'][$1] }
            when Array, Hash
              patch_keys(val)
            else
              raise TypeError, "String, Array or Hash expected, got #{val.class}"
          end
        }
      else
        raise TypeError, "Array or Hash expected, got #{cont.class}"
    end
  end

  def usage(text)
    sep1, sep2 = %w[- =].map { |char| char * 79 }

    puts sep1, text, sep1 unless text.empty?

    abort unless @options

    puts "USAGE: #{$0}", sep2, @options['command-line-options'].map { |opt, att|
      '%-8s %2s %3s %s' % [
        opt[0..7], att['opt'], att.has_key?('value') ? 'val' : '', att['comment']
      ]
    }, sep2

    abort
  end

end
