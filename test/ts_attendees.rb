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


require 'test/unit'
require 'lingo'


################################################################################
#
#		Hilfsroutinen für kurze Schreibweisen
def split( text )
	text =~ /^([^|]+)\|([^|]*)$/
	[$1.nil? ? '' : $1, $2.nil? ? '' : $2]
end

#		Erzeugt ein AgendaItem-Objekt	
def ai( text )
	c, p = split( text )
	AgendaItem.new( c, p )
end

#		Erzeugt ein Token-Objekt
def tk( text )
	f, a = split( text )
	Token.new( f, a )
end

#		Erzeugt ein Lexical-Objekt
def lx( text )
	f, a = split( text )
	Lexical.new( f, a )
end

#		Erzeugt ein Word-Objekt
def wd( text, *lexis )
	f, a = split( text )
	w = Word.new( f, a )
	lexis.each do |text|
		f, a = split( text )
		w << Lexical.new( f, a )
	end
	w 
end
#
################################################################################



################################################################################
#
#		TestCase erweitern für Attendee-Tests
#
class Test::Unit::TestCase

	alias old_init initialize

	def initialize(fname)
		old_init(fname)
		@name = $1.downcase if self.class.to_s =~ /TestAttendee(.*)/
		@output = Array.new
		
		Lingo.new('lingo.rb', [])
	end


	def meet(att_cfg, check=true)
		std_cfg = {'name'=>@name.capitalize}
		std_cfg.update({'in'=>'lines'}) unless @input.nil?
		std_cfg.update({'out'=>'output'}) unless @output.nil?

		@output.clear
		Lingo::meeting.reset
		inv_list = []
		inv_list << {'helper'=>{'name'=>'Helper', 'out'=>'lines', 'spool_from'=>@input}} unless @input.nil?
		inv_list << {@name=>std_cfg.update( att_cfg )}
		inv_list << {'helper'=>{'name'=>'Helper', 'in'=>'output', 'dump_to'=>@output}} unless @output.nil?
		Lingo::meeting.invite( inv_list )
		Lingo::meeting.start( 0 )

		assert_equal(@expect, @output) if check
	end

end	
#
################################################################################



################################################################################
#
#		Attendee Abbreviator
#
class TestAttendeeAbbreviator < Test::Unit::TestCase

	def test_basic
		@input = [
			tk('z.b|ABRV'), tk('.|PUNC'), 
			tk('im|WORD'), 
			tk('14.|NUMS'), 
			tk('bzw|WORD'), tk('.|PUNC'),
			tk('15.|NUMS'), 
			tk('Jh|WORD'), tk('.|PUNC'), 
			ai('EOL|')
		]
		@expect = [
			wd('z.b.|IDF', 'zum beispiel|w'),
			tk('im|WORD'), 
			tk('14.|NUMS'), 
			wd('bzw.|IDF', 'beziehungsweise|w'),
			tk('15.|NUMS'), 
			wd('Jh.|IDF', 'jahrhundert|s'),
			ai('EOL|')
		]
		meet({'source'=>'sys-abk'})
	end

end
#
################################################################################



################################################################################
#
#		Attendee Decomposer
#
class TestAttendeeDecomposer < Test::Unit::TestCase

	def test_basic
		@input = [
			wd('Kleinseite|?'),
			wd('Arrafat-Nachfolger|?'),
			wd('Afganistan-Reisen|?'),
			wd('Kompositumzerlegung|?'),
			wd('Kompositumzerlegung|?')
		]
		@expect = [
			wd('Kleinseite|KOM', 'kleinseite|k', 'klein|a+', 'seite|s+'),
			wd('Arrafat-Nachfolger|KOM', 'arrafat-nachfolger|k', 'nachfolger|s+', 'arrafat|x+'),
			wd('Afganistan-Reisen|KOM', 'afganistan-reise|k', 'reise|s+', 'reisen|v+', 'afganistan|x+'),
			wd('Kompositumzerlegung|KOM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+'),
			wd('Kompositumzerlegung|KOM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+')
		]
		meet({'source'=>'sys-dic'})
	end
	
end
#
################################################################################



################################################################################
#
#		Attendee Multiworder
#
class TestAttendeeMultiworder < Test::Unit::TestCase

	def test_basic
		@input = [
			ai('FILE|mul.txt'),
			#	John_F_._Kennedy
			wd('John|IDF', 'john|e'), wd('F|?'), tk('.|PUNC'), wd('Kennedy|IDF', 'kennedy|e'),
			#	John_F_Kennedy
			wd('John|IDF', 'john|e'), wd('F|?'), wd('Kennedy|IDF', 'kennedy|e'),
			#	John_F_Kennedy_.
			wd('John|IDF', 'john|e'), wd('F|?'), wd('Kennedy|IDF', 'kennedy|e'), tk('.|PUNC'),
			#	a_priori
			wd('a|?'), wd('priori|IDF', 'priori|w'),
			#	Ableitung_nicht_ganzzahliger_Ordnung
			wd('Ableitung|IDF', 'ableitung|s'),
			wd('nicht|IDF', 'nicht|w'),
			wd('ganzzahliger|IDF', 'ganzzahlig|a'),
			wd('Ordnung|IDF', 'ordnung|s'),
			#	Academic_learning_time_in_physical_education
			wd('academic|?'), wd('learning|?'), wd('time|IDF', 'timen|v'), 
			wd('in|IDF', 'in|t'), wd('physical|?'), wd('education|?'),
			#	Satzende
			tk('.|PUNC'),
			ai('EOF|mul.txt')
		]
		@expect = [
			ai('FILE|mul.txt'),
			#	John_F_._Kennedy
			wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
			wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
			#	John_F_Kennedy
			wd('John F Kennedy|MUL', 'john f. kennedy|m'),
			wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
			#	John_F_Kennedy_.
			wd('John F Kennedy|MUL', 'john f. kennedy|m'),
			wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
			tk('.|PUNC'),
			#	a_priori
			wd('a priori|MUL', 'a priori|m'),
			wd('a|MU?'), wd('priori|IDF', 'priori|w'),
			#	Ableitung_nicht_ganzzahliger_Ordnung
			wd('Ableitung nicht ganzzahliger Ordnung|MUL', 'ableitung nicht ganzzahliger ordnung|m'),
			wd('Ableitung|IDF', 'ableitung|s'),
			wd('nicht|IDF', 'nicht|w'),
			wd('ganzzahliger|IDF', 'ganzzahlig|a'),
			wd('Ordnung|IDF', 'ordnung|s'),
			#	Academic_learning_time_in_physical_education
			wd('academic learning time in physical education|MUL', 'academic learning time in physical education|m'),
			wd('academic|MU?'), wd('learning|MU?'), wd('time|IDF', 'timen|v'), 
			wd('in|IDF', 'in|t'), wd('physical|MU?'), wd('education|MU?'),
			#	Satzende
			tk('.|PUNC'),
			ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mul'})
	end


	def test_ending_count
		@input = [
			ai('FILE|mul.txt'),
			wd('John|IDF', 'john|e'), wd('F|?'), tk('.|PUNC'), wd('Kennedy|IDF', 'kennedy|e'),
			wd('war|IDF', 'war|w'), wd('einmal|IDF', 'einmal|w'), wd('Präsident|IDF', 'präsident|s'), tk('.|PUNC'),
			ai('EOF|mul.txt')
		]
		@expect = [
			ai('FILE|mul.txt'),
			wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
			wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
			wd('war|IDF', 'war|w'), wd('einmal|IDF', 'einmal|w'), wd('Präsident|IDF', 'präsident|s'), tk('.|PUNC'),
			ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mul'})

		#		
		@input.delete_at(-3)
		@expect = [
			ai('FILE|mul.txt'),
			wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
			wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
			wd('war|IDF', 'war|w'), wd('einmal|IDF', 'einmal|w'), tk('.|PUNC'),
			ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mul'})
		
		#		
		@input.delete_at(-3)
		@expect = [
			ai('FILE|mul.txt'),
			wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
			wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
			wd('war|IDF', 'war|w'), tk('.|PUNC'),
			ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mul'})
		
		#		
		@input.delete_at(-3)
		@expect = [
			ai('FILE|mul.txt'),
			wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
			wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
			tk('.|PUNC'),
			ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mul'})
		
	end


	def test_two_sources_mode_first
		#	in keinen WB enthalten
		@input = [
			wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mul,tst-mu2', 'mode'=>'first'})

		
		#	im ersten WB enthalten
		@input = [
			wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'), 
			wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mul,tst-mu2', 'mode'=>'first'})

		
		#	im zweiten WB enthalten
		@input = [
			wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'), 
			wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt') 
		]
		meet({'source'=>'tst-mul,tst-mu2', 'mode'=>'first'})

		
		#	in beiden WB enthalten
		@input = [
			wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('azyklischen Bewegungen|MUL', 'chaotisches movement|m'),
			wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mul,tst-mu2', 'mode'=>'first'})
	end


	def test_two_sources_mode_first_flipped
		#	in keinen WB enthalten
		@input = [
			wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'first'})

		#	im ersten WB enthalten
		@input = [
			wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'), 
			wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'first'})
		
		#	im zweiten WB enthalten
		@input = [
			wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'), 
			wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt') 
		]
		meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'first'})
		
		#	in beiden WB enthalten
		@input = [
			wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('azyklischen Bewegungen|MUL', 'azyklische bewegung|m'),
			wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'first'})
	end


	def test_select_two_sources_mode_all
		#	in keinen WB enthalten
		@input = [
			wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'all'})

		#	im ersten WB enthalten
		@input = [
			wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'), 
			wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'all'})
		
		#	im zweiten WB enthalten
		@input = [
			wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'), 
			wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt') 
		]
		meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'all'})
		
		#	in beiden WB enthalten
		@input = [
			wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('azyklischen Bewegungen|MUL', 'azyklische bewegung|m', 'chaotisches movement|m'),
			wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'all'})
	end


	def test_select_two_sources_mode_def
		#	in keinen WB enthalten
		@input = [
			wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mu2,tst-mul'})

		#	im ersten WB enthalten
		@input = [
			wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'), 
			wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mu2,tst-mul'})
		
		#	im zweiten WB enthalten
		@input = [
			wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'), 
			wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt') 
		]
		meet({'source'=>'tst-mu2,tst-mul'})
		
		#	in beiden WB enthalten
		@input = [
			wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
		]
		@expect = [
			wd('azyklischen Bewegungen|MUL', 'azyklische bewegung|m', 'chaotisches movement|m'),
			wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
		]
		meet({'source'=>'tst-mu2,tst-mul'})
	end

end
#
################################################################################



################################################################################
#
#		Attendee Noneword_filter
#
class TestAttendeeNoneword_filter < Test::Unit::TestCase

	def test_basic
		@input = [wd('Eins|IDF'), wd('Zwei|?'), wd('Drei|IDF'), wd('Vier|?'), ai('EOF|')]
		@expect = ['vier', 'zwei', ai('EOF|')]
		meet({})
	end

end
#
################################################################################



################################################################################
#
#		Attendee Objectfilter
#
class TestAttendeeObjectfilter < Test::Unit::TestCase

	def test_basic
		@input = [wd('Eins|IDF'), wd('zwei|?'), wd('Drei|IDF'), wd('vier|?'), ai('EOF|')]
		@expect = [wd('Eins|IDF'), wd('Drei|IDF'), ai('EOF|')]
		meet({'objects'=>'obj.form =~ /^[A-Z]/'})
	end

end
#
################################################################################



################################################################################
#
#		Attendee Sequencer
#
class TestAttendeeSequencer < Test::Unit::TestCase

	def test_basic
		@input = [
			#	AS
			wd('Die|IDF', 'die|w'), 
			wd('helle|IDF', 'hell|a'),
			wd('Sonne|IDF', 'sonne|s'),
			tk('.|PUNC'),
			#	AK
			wd('Der|IDF', 'der|w'), 
			wd('schöne|IDF', 'schön|a'),
			wd('Sonnenuntergang|KOM', 'sonnenuntergang|k', 'sonne|s', 'untergang|s'),
			ai('EOF|')
		]
		@expect = [
			#	AS
			wd('Die|IDF', 'die|w'), 
			wd('sonne, hell|SEQ', 'sonne, hell|q'),
			wd('helle|IDF', 'hell|a'),
			wd('Sonne|IDF', 'sonne|s'),
			tk('.|PUNC'),
			#	AK
			wd('Der|IDF', 'der|w'), 
			wd('sonnenuntergang, schön|SEQ', 'sonnenuntergang, schön|q'),
			wd('schöne|IDF', 'schön|a'),
			wd('Sonnenuntergang|KOM', 'sonnenuntergang|k', 'sonne|s', 'untergang|s'),
			ai('EOF|')
		]
		meet({'stopper'=>'PUNC,OTHR', 'source'=>'sys-mul'})
	end

end
#
################################################################################



################################################################################
#
#		Attendee Synonymer
#
class TestAttendeeSynonymer < Test::Unit::TestCase

	def test_basic
		@input = [wd('abtastzeiten|IDF', 'abtastzeit|s')]
		@expect = [wd('abtastzeiten|IDF', 'abtastzeit|s', 'abtastfrequenz|y', 'abtastperiode|y')]
		meet({'source'=>'sys-syn', 'check'=>'-,MUL'})
#		@expect.each_index {|i| assert_equal(@expect[i], @output[i]) }
	end


	def test_first
		@input = [wd('Aktienanleihe|IDF', 'aktienanleihe|s')]
		@expect = [wd('Aktienanleihe|IDF', 'aktienanleihe|s', 'aktien-anleihe|y',
			'reverse convertible bond|y', 'reverse convertibles|y')]
		meet({'source'=>'sys-syn,tst-syn', 'check'=>'-,MUL', 'mode'=>'first'})
	end

	
	def test_all
		@input = [wd('Kerlchen|IDF', 'kerlchen|s')]
		@expect = [wd('Kerlchen|IDF', 'kerlchen|s', 'zwerg-nase|y')]
		meet({'source'=>'sys-syn,tst-syn', 'check'=>'-,MUL', 'mode'=>'all'})
	end
	
end
#
################################################################################



################################################################################
#
#		Attendee Textreader
#
class TestAttendeeTextreader < Test::Unit::TestCase

	def test_lir_file
		@expect = [
			ai('LIR-FORMAT|'), ai('FILE|test/lir.txt'), 
			ai('RECORD|00237'),
			'020: GERHARD.',
			'025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
			'056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.',
			ai('RECORD|00238'),
			'020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 
			'025: das DFG-Projekt GERHARD.',
			ai('RECORD|00239'),
			'020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.',
			'056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.',
			ai('EOF|test/lir.txt')
		]
		meet({'files'=>'test/lir.txt', 'lir-record-pattern'=>'^\[(\d+)\.\]'})
	end


	def test_lir_file_another_pattern
		@expect = [
			ai('LIR-FORMAT|'), ai('FILE|test/lir2.txt'), 
			ai('RECORD|00237'),
			'020: GERHARD.',
			'025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
			'056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.',
			ai('RECORD|00238'),
			'020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 
			'025: das DFG-Projekt GERHARD.',
			ai('RECORD|00239'),
			'020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.',
			'056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.',
			ai('EOF|test/lir2.txt')
		]
		meet({'files'=>'test/lir2.txt', 'lir-record-pattern'=>'^\021(\d+)\022'})
	end


	def test_normal_file
		@expect = [
			ai('FILE|test/mul.txt'),
			'Die abstrakte Kunst ist schön.',
			ai('EOF|test/mul.txt')
		]
		meet({'files'=>'test/mul.txt'})
	end

end
#
################################################################################



################################################################################
#
#		Attendee Textwriter
#
class TestAttendeeTextwriter < Test::Unit::TestCase

	def setup
		@data = [
			ai('FILE|test/test.txt'),
			wd('Dies|IDF'),
			wd('ist|IDF'),
			wd('eine|IDF'),
			wd('Zeile|IDF'),
			tk('.|PUNC'),
			ai('EOL|test/test.txt'),
			wd('Dies|IDF'),
			wd('ist|IDF'),
			wd('eine|IDF'),
			wd('zweite|IDF'),
			wd('Zeile|IDF'),
			tk('.|PUNC'),
			ai('EOL|test/test.txt'),
			ai('EOF|test/test.txt')
		]
	end


	def test_basic
		@input = @data
		@expect = [ "Dies,ist,eine,Zeile,.\n", "Dies,ist,eine,zweite,Zeile,.\n" ]
		meet({'ext'=>'tst',  'sep'=>','}, false)
		
		@output = File.open('test/test.tst').readlines
		assert_equal(@expect, @output)
	end


	def test_complex
		@input = @data
		@expect = [ "Dies-ist-eine-Zeile-.\n", "Dies-ist-eine-zweite-Zeile-.\n" ]
		meet({'ext'=>'yip',  'sep'=>'-'}, false)
		
		@output = File.open('test/test.yip').readlines
		assert_equal(@expect, @output)
	end


	def test_crlf
		@input = @data
		@expect = [ "Dies\n", "ist\n", "eine\n", "Zeile\n", ".\n", "Dies\n", "ist\n", "eine\n", "zweite\n", "Zeile\n", ".\n" ]
		meet({'sep'=>"\n"}, false)
		
		@output = File.open('test/test.txt2').readlines
		assert_equal(@expect, @output)
	end


	def test_lir_file
		@input = [
			ai('LIR-FORMAT|'), ai('FILE|test/lir.txt'),
			ai('RECORD|00237'),
			'020: GERHARD.',
			'025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
			'056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.',
			ai('RECORD|00238'),
			'020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 
			'025: das DFG-Projekt GERHARD.',
			ai('RECORD|00239'),
			'020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.',
			'056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.',
			ai('EOF|test/lir.txt')
		]
		@expect = [
			"00237*020: GERHARD. 025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressour\
cen. 056: Die intellektuelle Erschlie\337ung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.\n",
			"00238*020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen. 025: das D\
FG-Projekt GERHARD.\n",
			"00239*020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter. 056: \"Das Buch ist ein praxisbezogenes VADEMECUM\
 f\374r alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.\n"
		]
		meet({'ext'=>'csv', 'lir-format'=>nil}, false)
		
		@output = File.open('test/lir.csv').readlines
		assert_equal(@expect, @output)
	end


	def test_nonewords
		@input = [ai('FILE|test/text.txt'), 'Nonwörter', 'Nonsense', ai('EOF|test/text.txt')]
		@expect = [ "Nonwörter\n", "Nonsense" ]
		meet({'ext'=>'non', 'sep'=>"\n"}, false)
		
		@output = File.open('test/text.non').readlines
		assert_equal(@expect, @output)
	end

end
#
################################################################################



################################################################################
#
#		Attendee Tokenizer
#
class TestAttendeeTokenizer < Test::Unit::TestCase

	def test_basic
		@input = ["Dies ist ein Test."]
		@expect = [tk('Dies|WORD'), tk('ist|WORD'), tk('ein|WORD'), tk('Test|WORD'), tk('.|PUNC')]
		meet({})
	end


	def test_complex
		@input = ["1964 www.vorhauer.de bzw. nasenbär, ()"]
		@expect = [
			tk('1964|NUMS'),
			tk('www.vorhauer.de|URLS'),
			tk('bzw|WORD'), 
			tk('.|PUNC'), 
			tk('nasenbär|WORD'), 
			tk(',|PUNC'), 
			tk('(|OTHR'), 
			tk(')|OTHR')
		]
		meet({})
	end

end
#
################################################################################



################################################################################
#
#		Attendee Variator
#
class TestAttendeeVariator < Test::Unit::TestCase

	def test_basic
		@input = [wd('fchwarz|?'), wd('fchilling|?'), wd('iehwarzfchilling|?'), wd('fchiiiirg|?')]
		@expect = [
			wd('*schwarz|IDF', 'schwarz|a'),
			wd('*schilling|IDF', 'schilling|s'),
			wd('*schwarzschilling|KOM', 'schwarzschilling|k', 'schwarz|a+', 'schilling|s+'),
			wd('fchiiiirg|?')
		]
		meet({'source'=>'sys-dic'})
	end
	
end
#
################################################################################



################################################################################
#
#		Attendee Vector_filter
#
class TestAttendeeVector_filter < Test::Unit::TestCase

	def setup
		@input = [
			ai('FILE|test'),
			wd('Testwort|IDF', 'substantiv|s', 'adjektiv|a', 'verb|v', 'eigenname|e', 'mehrwortbegriff|m'), 
			ai('EOF|test')
		]
	end


	def test_basic
		@expect = [ai('FILE|test'), 'substantiv', ai('EOF|test')]
		meet({})
	end


	def test_lexicals
		@expect = [ai('FILE|test'), 'adjektiv', 'eigenname', 'substantiv', 'verb', ai('EOF|test')]
		meet({'lexicals'=>'[save]'})
	end


	def test_sort_term_abs
		@expect = [ai('FILE|test'), '1 adjektiv', '1 eigenname', '1 substantiv', '1 verb', ai('EOF|test')]
		meet({'lexicals'=>'[save]', 'sort'=>'term_abs'})
	end


	def test_sort_term_rel
		@expect = [ai('FILE|test'), '1.00000 adjektiv', '1.00000 eigenname', '1.00000 substantiv', '1.00000 verb', ai('EOF|test')]
		meet({'lexicals'=>'[save]', 'sort'=>'term_rel'})
	end

	def test_sort_sto_abs
		@expect = [ai('FILE|test'), 'adjektiv {1}', 'eigenname {1}', 'substantiv {1}', 'verb {1}', ai('EOF|test')]
		meet({'lexicals'=>'[save]', 'sort'=>'sto_abs'})
	end


	def test_sort_sto_rel
		@expect = [ai('FILE|test'), 'adjektiv {1.00000}', 'eigenname {1.00000}', 'substantiv {1.00000}', 'verb {1.00000}', ai('EOF|test')]
		meet({'lexicals'=>'[save]', 'sort'=>'sto_rel'})
	end

end
#
################################################################################



################################################################################
#
#		Attendee Wordsearcher
#
class TestAttendeeWordsearcher < Test::Unit::TestCase

	def setup
		@test_synonyms = [
			lx('experiment|y'), lx('kontrolle|y'), lx('probelauf|y'),
			lx('prüfung|y'), lx('test|y'), lx('testlauf|y'),
			lx('testversuch|y'), lx('trockentest|y'), lx('versuch|y')
		]
	end
	
	
	def test_basic
		@input = [tk('Dies|WORD'), tk('ist|WORD'), tk('ein|WORD'), tk('Test|WORD'), tk('.|PUNC'), ai('EOL|')]
		@expect = [
			wd('Dies|IDF', 'dies|w'),
			wd('ist|IDF', 'ist|t'),
			wd('ein|IDF', 'ein|t'),
			wd('Test|IDF', 'test|s'),
			tk('.|PUNC'),
			ai('EOL|')
		]
		meet({'source'=>'sys-dic,sys-syn,sys-mul'})
	end


	def test_mode
		@input = [tk('Dies|WORD'), tk('ist|WORD'), tk('ein|WORD'), tk('Test|WORD'), tk('.|PUNC'), ai('EOL|')]
		@expect = [
			wd('Dies|IDF', 'dies|w'),
			wd('ist|IDF', 'ist|t'),
			wd('ein|IDF', 'ein|t'),
			wd('Test|IDF', 'test|s'),
			tk('.|PUNC'),
			ai('EOL|')
		]
		meet({'source'=>'sys-syn,sys-dic', 'mode'=>'first'})
	end


	def test_two_sources_mode_first
		@input = [
			tk('Hasennasen|WORD'),
			tk('Knaller|WORD'),
			tk('Lex-Lingo|WORD'),
			tk('A-Dur|WORD'),
			ai('EOL|')
		]
		@expect = [
			wd('Hasennasen|?'),
			wd('Knaller|IDF', 'knaller|s'),
			wd('Lex-Lingo|IDF', 'super indexierungssystem|m'),
			wd('A-Dur|IDF', 'a-dur|s'),
			ai('EOL|')
		]
		meet({'source'=>'sys-dic,tst-dic', 'mode'=>'first'})
	end


	def test_two_sources_mode_first_flipped
		@input = [
			tk('Hasennasen|WORD'),
			tk('Knaller|WORD'),
			tk('Lex-Lingo|WORD'),
			tk('A-Dur|WORD'),
			ai('EOL|')
		]
		@expect = [
			wd('Hasennasen|?'),
			wd('Knaller|IDF', 'knaller|s'),
			wd('Lex-Lingo|IDF', 'super indexierungssystem|m'),
			wd('A-Dur|IDF', 'b-dur|s'),
			ai('EOL|')
		]
		meet({'source'=>'tst-dic,sys-dic', 'mode'=>'first'})
	end


	def test_select_two_sources_mode_all
		@input = [
			tk('Hasennasen|WORD'),
			tk('Knaller|WORD'),
			tk('Lex-Lingo|WORD'),
			tk('A-Dur|WORD'),
			ai('EOL|')
		]
		@expect = [
			wd('Hasennasen|?'),
			wd('Knaller|IDF', 'knaller|s'),
			wd('Lex-Lingo|IDF', 'super indexierungssystem|m'),
			wd('A-Dur|IDF', 'a-dur|s', 'b-dur|s'),
			ai('EOL|')
		]
		meet({'source'=>'sys-dic,tst-dic', 'mode'=>'all'})
	end


	def test_select_two_sources_mode_def
		@input = [
			tk('Hasennasen|WORD'),
			tk('Knaller|WORD'),
			tk('Lex-Lingo|WORD'),
			tk('A-Dur|WORD'),
			ai('EOL|')
		]
		@expect = [
			wd('Hasennasen|?'),
			wd('Knaller|IDF', 'knaller|s'),
			wd('Lex-Lingo|IDF', 'super indexierungssystem|m'),
			wd('A-Dur|IDF', 'a-dur|s', 'b-dur|s'),
			ai('EOL|')
		]
		meet({'source'=>'sys-dic,tst-dic'})
	end

end
#
################################################################################