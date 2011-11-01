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

require 'unicode'
require 'pathname'

#
#    Util stellt Hilfsroutinen bereit, die der Denke des Autors besser entsprechen.
#

#    Erweiterung der Klasse String.
class String

  def downcase
    Unicode.downcase(self)
  end

end

class Pathname
  def create_path
    here = Pathname.new( '.' )
    self.split[0].each_filename do |path|
      here += path
      unless here.directory?
        here.mkdir(0777)
      end
    end
  end
end

unless ISITRUBY19

class String

  def encode!(*args); self; end

end

class IO

  def set_encoding(*args); self; end

end

class << File

  alias_method :_lingo_original_open, :open

  def open(*args, &block)
    args.pop if args.last.is_a?(Hash)
    _lingo_original_open(*args, &block)
  end

end

class Pathname

  alias_method :_lingo_original_each_line, :each_line

  def each_line(*args, &block)
    args.pop if args.last.is_a?(Hash)
    _lingo_original_each_line(*args, &block)
  end

end

end
