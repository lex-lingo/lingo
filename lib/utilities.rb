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


require 'pathname'

#
#    Util stellt Hilfsroutinen bereit, die der Denke des Autors besser entsprechen.
#




#    Erweiterung der Klasse String.
class String
  alias old_split split
  alias old_downcase downcase
  
  #    _str_.split( _anInteger_ ) -> _anArray_
  #
  #    Die Methode split wird um eine Aufruf-Variante erweitert, z.B.
  #
  #    <tt>"Wortklasse".split(4) -> ["Wort", "klasse"]</tt> 
  def split(*par)
    if par.size == 1 && par[0].kind_of?(Fixnum)
      [slice(0...par[0]), slice(par[0]..self.size-1)]
    else
      old_split(*par)
    end
  end
  
  
  def downcase # utf-8 downcase
    self.old_downcase.tr('ÄÖÜÁÂÀÉÊÈÍÎÌÓÔÒÚÛÙÝ', 'äöüáâàéêèíîìóôòúûùý')
  end
  
  
  HEX_CHARS = '0123456789abcdef'.freeze

  def to_x
    hex = ''
    each_byte { |byte|
      # To get a hex representation for a char we just utilize
      # the quotient and the remainder of division by base 16.
      q, r = byte.divmod(16)
      hex << HEX_CHARS[q] << HEX_CHARS[r]
    }
    hex
  end
  
  
  def from_x
    str, q, first = '', 0, false
    each_byte { |byte|
      byte = byte.chr

      # Our hex chars are 2 bytes wide, so we have to keep track
      # of whether it's the first or the second of the two.
      #
      # NOTE: inject with each_slice(2) would be a natural fit,
      # but it's kind of slow...
      if first = !first
        q = HEX_CHARS.index(byte)
      else
        # Now we got both parts, so let's do the
        # inverse of divmod(16): q * 16 + r
        str << q * 16 + HEX_CHARS.index(byte)
      end
    }
    str
  end


  #  als patch für dictionary.select.sort.uniqual
  def attr
    ''
  end

end


#    Erweiterung der Klasse File
class File

  #    File.change_ext( _fileName_, _aString_ ) -> _fileName_
  #
  #    Tauscht bei einem bestehenden Dateinamen die Endung aus.
  #
  #    File.change_ext('C:\dev\rubyling.rb', 'save') -> 'C:\dev\rubyling.save'
  def File.change_ext(fileName, ext)
    fileName =~ /^(.*\.)[^\.]+$/
    $1+ext
  end
  

  def File.obj_type(obj)
    db_re = Regexp.new($CFG['db-file-index-pattern'])
    begin
      obj_type = (File.stat(obj).directory?) ? 'dir' : 'file'
      if obj_type == 'file'
        found_index = 0
        File.open(obj, :encoding => ENC) { |file|
          (1..50).each { |i|
            found_index += 1 if file.gets =~ db_re 
          } 
        }
        obj_type = 'db' if found_index > 3
      end
      rescue StandardError
        obj_type = nil
    end
    obj_type
  end
  
end


class Array

  def uniq2
    if self.size > 1
      this = nil
      (self.size-1).downto(1) {|i|
        if self[i]==this
          self.delete_at(i)
        else
          this = self[i]
        end
      }
    end
    self
  end
  
  def uniqual
    result = self.dup
    if result.size > 1
      this = result[-1]
      (result.size-2).downto(0) {|i|
        if result[i]==this
          result.delete_at(i)
        else
          this = result[i]
        end
      }
    end
    result
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
