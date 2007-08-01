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


require 'pathname'

#
#		Util stellt Hilfsroutinen bereit, die der Denke des Autors besser entsprechen.
#




#		Erweiterung der Klasse String.
class String
	alias old_split split
	alias old_downcase downcase
	
	#		_str_.split( _anInteger_ ) -> _anArray_
	#
	#		Die Methode split wird um eine Aufruf-Variante erweitert, z.B.
	#
	#		<tt>"Wortklasse".split(4) -> ["Wort", "klasse"]</tt> 
	def split(*par)
		if par.size == 1 && par[0].kind_of?(Fixnum)
			[slice(0...par[0]), slice(par[0]..self.size-1)]
		else
			old_split(*par)
		end
	end
	
	
	def downcase # utf-8 downcase
		self.old_downcase.tr('ÄÖÜÁÂÀÉÊÈÍÎÌÓÔÒÚÛÙİ', 'äöüáâàéêèíîìóôòúûùı')
	end
	
	
	@@hex_chars = '0123456789abcdef'

	def to_x
		hex = ''
		self.each_byte {|b|
			hex << @@hex_chars[(b & 0xf0) /16]
			hex << @@hex_chars[b & 0x0f]
		}
		hex
	end
	
	
	def from_x
		str = ''
		b = 0
		h = 1
		self.each_byte {|c|
			if h==1
				b = @@hex_chars.index(c) * 16
			else
				b += @@hex_chars.index(c)
				str << b
			end
			h = 1 - h
		}
		str
	end


	#	als patch für dictionary.select.sort.uniqual
	def attr
		''
	end

end


#		Erweiterung der Klasse File
class File

	#		File.change_ext( _fileName_, _aString_ ) -> _fileName_
	#
	#		Tauscht bei einem bestehenden Dateinamen die Endung aus.
	#
	#		File.change_ext('C:\dev\rubyling.rb', 'save') -> 'C:\dev\rubyling.save'
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
				File.open(obj) { |file|
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
