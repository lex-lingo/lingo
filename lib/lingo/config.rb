# encoding: utf-8

# LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
# Mehrworterkennung und Relationierung.
#
# Copyright (C) 2005-2007 John Vorhauer
# Copyright (C) 2007-2011 John Vorhauer, Jens Wille
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
# For more information visit http://www.lex-lingo.de or contact me at
# welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
# Lex Lingo rules from here on

require 'yaml'
require_relative 'cli'

class Lingo

class Config

  def initialize(*args)
    @cli, @opts = CLI.new, {}

    @cli.execute(*args)
    @cli.options.each { |key, val| @opts[key.to_s] = val }

    { 'language' => 'lang', 'config' => 'cfg' }.each { |key, ext|
      @opts.update(load_yaml_file(@opts[key], ext))
    }

    Array(self['meeting/attendees']).each { |a|
      r = a['textreader'] or next

      f = @cli.files

      if i = r['files']
        r['files'] = i.strip == '$(files)' ?
          f : i.split(STRING_SEPERATOR_PATTERN)
      elsif !f.empty?
        r['files'] = f
      end

      break
    }
  end

  def [](key)
    key_to_nodes(key).inject(@opts) { |value, node| value[node] }
  end

  def []=(key, value)
    nodes = key_to_nodes(key); node = nodes.pop
    (self[nodes_to_key(nodes)] ||= {})[node] = value
  end

  def stdin
    @cli.stdin
  end

  def stdout
    @cli.stdout
  end

  def stderr
    @cli.stderr
  end

  private

  def key_to_nodes(key)
    key.downcase.split('/')
  end

  def nodes_to_key(nodes)
    nodes.join('/')
  end

  def load_yaml_file(name, ext)
    file = name.sub(/(?:\.[^.]+)?\z/, '.' << ext)
    file = File.join(BASE, file) unless name.include?('/')

    @cli.quit("File not found: #{file}") unless File.readable?(file)

    File.open(file, :encoding => ENC) { |f| YAML.load(f) }
  end

end

end
