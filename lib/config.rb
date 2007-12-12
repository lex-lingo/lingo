#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung, 
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005  John Vorhauer
#
#  This program is free software; you can redistribute it and/or modify it under 
#  the terms of the GNU General Public License as published by the Free Software 
#  Foundation;  either version 2 of the License, or  (at your option)  any later
#  version.
#
#  This program is distributed  in the hope  that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
#  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#  You should have received a copy of the  GNU General Public License along with 
#  this program; if not, write to the Free Software Foundation, Inc., 
#  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
#  For more information visit http://www.lex-lingo.de or contact me at
#  welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
#  Lex Lingo rules from here on


require 'yaml'

class LingoConfig

private

  def initialize(prog=$0, cmdline=$*)
    @keys = {}
    
    @options = load_yaml_file(prog, '.opt')
    @keys['cmdline'] = parse_cmdline(cmdline, @options)
    usage('') if @keys['cmdline']['usage']
    
    @keys.update(load_yaml_file(@keys['cmdline']['language'], '.lang'))
    @keys.update(load_yaml_file(@keys['cmdline']['config'], '.cfg'))

    patch_keys(@keys['language'])
    patch_keys(@keys['meeting'])
  end


  def parse_cmdline(cmdline, hash)
    keys = Hash.new
    non_hyphen_opt = nil

    #  Alle Hyphen-Parameter auslesen
    hash['command-line-options'].each_pair { |option, attr|

      if attr['opt'].nil?
        non_hyphen_opt = option
        next
      end

      #  Option in der Kommandozeile suchen
      idx = cmdline.index(attr['opt'])
      if idx.nil?
        #  Nicht angegeben, Defaultwert verwenden
        keys[option] = attr['default'] || false
      else
        #  Option angegeben, Wert ermitteln
        if attr.has_key?('value')
          usage("Option #{opt} verlangt die Angabe eines Wertes!") if (cmdline.size<=idx || cmdline[idx+1][0]==45) # '-'

          keys[option] = cmdline[idx+1]
          cmdline.delete_at(idx+1)
        else
          keys[option] = true
        end
        cmdline.delete_at(idx)
      end

    } unless hash.nil?

    opts = cmdline.collect { |p| p if p[0]==45 }.compact.join('|')
    usage("Unbekannte Optionen (#{opts})!") unless opts==''

    keys[non_hyphen_opt] = cmdline.join('|')
    
    keys
  end


  def load_yaml_file(file_name, file_ext)
    tree = nil
    
    if file_name =~ /\./
      yaml_file = file_name.sub(/\.([^\.]+)$/, file_ext)
    else
      yaml_file = file_name + file_ext
    end
    usage("Datei #{yaml_file} nicht vorhanden") unless File.exist?(yaml_file)

    File.open(yaml_file) { |file| tree = YAML.load(file) }
    tree
  end


  def patch_keys(cont)
    case 
    when cont.is_a?(Hash)
      cont.each_pair do |k,v|
        case
          when v.is_a?(String)
            cont[k].gsub!(   %r|\$\((.+?)\)|   ) { @keys['cmdline'][$1] }
          when v.is_a?(Hash) || v.is_a?(Array)
            patch_keys(v)
        end
      end
    when cont.is_a?(Array)
      cont.each do |v|
        case
          when v.is_a?(String)
            cont[cont.index(v)].gsub!(   %r|\$\((.+?)\)|   ) { @keys['cmdline'][$1] }
          when v.is_a?(Hash) || v.is_a?(Array)
            patch_keys(v)
        end
      end
    end
  end


  def usage(text)
    width = 79
    puts '-'*width
    puts text
    puts '-'*width

    exit( 1 ) if @options.nil?
    
    puts "USAGE: #{$0}"
    puts '='*width

    @options['command-line-options'].each_pair { |opt, att|
      printf "%-8s %2s %3s %s", opt[0..7], att['opt'], att.has_key?( 'value' ) ? 'val' : '', att['comment']
    }
    puts '='*width
    exit( 1 )
  end


public

  #  muss ein ergebnis != nil zurückgeben, sonst fehler
  def [](key)
    if @keys.nil?
      raise "Keine Konfiguration geladen!"
    else
      value = @keys
    end
    parent_node = '/'

    #  Pfad entlang gehen
    key.downcase.split('/').each do |node|
      value = value[node]
      parent_node = node
    end
    value
  end

end
