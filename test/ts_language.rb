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
require 'fileutils'
require 'lingo'

include FileUtils::Verbose

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
#		LexicalHash
#
class TestLexicalHash < Test::Unit::TestCase

	def setup
		Lingo.new('lingo.rb', [])
		@database_config = Lingo.config['language/dictionary/databases']
	end

	
	def test_params
		#	Datenquelle nicht in Konfiguration enthalten
		assert_raise(SystemExit) { LexicalHash.new( 'nonsens' ) }
	end
	
	#	TODO: Crypt testen...
	
	def test_cache
		ds = LexicalHash.new( 'sys-dic' )
		assert_equal([lx('regen|s'), lx('regen|v'), lx('rege|a')], ds['regen'])
		assert_equal([lx('regen|s'), lx('regen|v'), lx('rege|a')], ds['regen'])
		assert_equal([lx('regen|s'), lx('regen|v'), lx('rege|a')], ds['regen'])
		ds.close
	end

	
	def test_report
		ds = LexicalHash.new( 'tst-syn' )
		ds['abwickeln']		#	source read
		ds['abwickeln']		#	cache hit
		ds['regen']			#	source read
		ds['nonesens']		#	source read, nothing found
		
		expect = { \
			"tst-syn: cache hits" => 1, \
			"tst-syn: total requests" => 4, \
			"tst-syn: source reads" => 3, \
			"tst-syn: data found" => 2
		}
		
		assert_equal(expect, ds.report)
		ds.close
	end


	def test_auto_create
		txt_file = @database_config['tst-sgw']['name']
		sto_file = txt_file.gsub(/^de[\/]/, 'de/store/').gsub(/\.txt/, '.pag')
		
		ds = LexicalHash.new( 'tst-sgw' )
		assert_equal([lx('substantiv|s')], ds['substantiv'])
		ds.close

		#	Keine Store-Datei vorhanden, nur Text vorhanden
		File.delete(sto_file)
		ds = LexicalHash.new( 'tst-sgw' )
		assert_equal([lx('substantiv|s')], ds['substantiv'])
		ds.close

		#	Store vorhanden, aber Text ist neuer
		ds = LexicalHash.new( 'tst-sgw' )
		assert_equal([lx('substantiv|s')], ds['substantiv'])
		ds.close
	end

	
	def test_singleword
		ds = LexicalHash.new( 'tst-sgw' )
		assert_equal([lx('substantiv|s')], ds['substantiv'])
		assert_equal([lx('mehr wort gruppe|m')], ds['mehr wort gruppe'])
		assert_equal(nil, ds['nicht vorhanden'])
		ds.close
	end

	
	def test_keyvalue
		ds = LexicalHash.new( 'sys-mul' )
		assert_equal([lx('abelscher ring ohne nullteiler|m')], ds['abelscher ring ohne nullteiler'])
		assert_equal(['*4'], ds['abelscher ring ohne'])
		assert_equal([lx('alleinreisende frau|m')], ds['alleinreisende frau'])
		assert_equal([lx('abschaltbarer leistungshalbleiter|m')], ds['abschaltbarer leistungshalbleiter'])
		assert_equal(nil, ds['abschaltbar leistungshalbleiter'])
		ds.close
	end


	def test_wordclass
		ds = LexicalHash.new( 'sys-dic' )
		assert_equal([lx('a-dur|s')], ds['a-dur'])
		assert_equal([lx('aalen|e')], ds['aalen'])
		assert_equal([lx('abarbeiten|v'), lx('abarbeitend|a')], ds['abarbeitend'])
		ds.close
	end

	
	def test_multivalue
		ds = LexicalHash.new( 'sys-syn' )
#		assert_equal([lx('abrollen', LA_SYNONYM), lx('abschaffen', LA_SYNONYM), lx('abwickeln', LA_SYNONYM), lx('auflösen (geschäft)','y')], ds['abwickeln'])
#		assert_equal([lx('niederschlag', LA_SYNONYM), lx('regen', LA_SYNONYM), lx('schauer', LA_SYNONYM)], ds['regen'])
		ds.close
	end

end
#
################################################################################



################################################################################
#
#		Dictionary
#
class TestDictionary < Test::Unit::TestCase

	def setup
		Lingo.new('lingo.rb', [])
		@dictionary_config = Lingo.config['language/dictionary']
	end

	
	def test_params
		#	Keine Sprach-Konfiguration angegeben
		assert_raise(RuntimeError) { Dictionary.new({'source'=>['sys-dic']}, nil) }
		#	Keine Parameter angegeben
		assert_raise(RuntimeError) { Dictionary.new(nil, @dictionary_config) }
		#	Falsche Parameter angegeben (Pflichtparameter ohne Defaultwert)
		assert_raise(RuntimeError) { Dictionary.new({'course'=>['sys-dic']}, @dictionary_config) }
	end


	def test_cache
		dic = Dictionary.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal([lx('nase|s')], dic.select('nase'))
		assert_equal([lx('nase|s')], dic.select('nase'))
		assert_equal([lx('nase|s')], dic.select('nase'))
		dic.close
	end

	
	def test_report
		dic = Dictionary.new({'source'=>['sys-dic']}, @dictionary_config)
		dic.select('abwickeln')		#	source read
		dic.select('abwickeln')		#	cache hit
		dic.select('regen')				#	source read
		dic.select('nonesens')		#	source read, nothing found
		
		expect = { 
			"sys-dic: total requests" => 4,
			"sys-dic: data found" => 2,
			"sys-dic: cache hits" => 1,
			"sys-dic: source reads" => 3
		}
		
		assert_equal(expect, dic.report)
		dic.close
	end


	def test_select_one_source
		dic = Dictionary.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal([lx('nase|s')], dic.select('nase'))
		assert_equal([lx('nase|s')], dic.select('NASE'))
		assert_equal([], dic.select('hasennasen'))
		dic.close
	end

	
	def test_select_two_sources_mode_first
		dic = Dictionary.new({'source'=>['sys-dic', 'tst-dic'], 'mode'=>'first'}, @dictionary_config)
		#	in keiner Quelle vorhanden
		assert_equal([], dic.select('hasennasen'))
		#	nur in erster Quelle vorhanden
		assert_equal([lx('knaller|s')], dic.select('knaller'))
		#	nur in zweiter Quelle vorhanden
		assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
		#	in beiden Quellen vorhanden
		assert_equal([lx('a-dur|s')], dic.select('a-dur'))
		dic.close
	end


	def test_select_two_sources_mode_first_flipped
		dic = Dictionary.new({'source'=>['tst-dic','sys-dic'], 'mode'=>'first'}, @dictionary_config)
		#	in keiner Quelle vorhanden
		assert_equal([], dic.select('hasennasen'))
		#	nur in erster Quelle vorhanden
		assert_equal([lx('knaller|s')], dic.select('knaller'))
		#	nur in zweiter Quelle vorhanden
		assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
		#	in beiden Quellen vorhanden
		assert_equal([lx('b-dur|s')], dic.select('a-dur'))
		dic.close
	end


	def test_select_two_sources_mode_all
		dic = Dictionary.new({'source'=>['sys-dic','tst-dic'], 'mode'=>'all'}, @dictionary_config)
		#	in keiner Quelle vorhanden
		assert_equal([], dic.select('hasennasen'))
		#	nur in erster Quelle vorhanden
		assert_equal([lx('knaller|s')], dic.select('knaller'))
		#	nur in zweiter Quelle vorhanden
		assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
		#	in beiden Quellen vorhanden
		assert_equal([lx('a-dur|s'), lx('b-dur|s')], dic.select('a-dur'))
		assert_equal([lx('aas|s')], dic.select('aas'))
		dic.close
	end


	def test_select_two_sources_mode_default
		dic = Dictionary.new({'source'=>['sys-dic','tst-dic']}, @dictionary_config)
		#	in keiner Quelle vorhanden
		assert_equal([], dic.select('hasennasen'))
		#	nur in erster Quelle vorhanden
		assert_equal([lx('knaller|s')], dic.select('knaller'))
		#	nur in zweiter Quelle vorhanden
		assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
		#	in beiden Quellen vorhanden
		assert_equal([lx('a-dur|s'), lx('b-dur|s')], dic.select('a-dur'))
		assert_equal([lx('aas|s')], dic.select('aas'))
		dic.close
	end


	def test_suffix_lexicals
		dic = Dictionary.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal([lx('mau|s'), lx('mauer|s')], dic.suffix_lexicals('mauern'))
		assert_equal([lx('hasen|s'), lx('hasen|v'), lx('hasen|e')], dic.suffix_lexicals('hasens'))
		assert_equal([lx('schönst|s'), lx('schön|a'), lx('schönst|a')], dic.suffix_lexicals('schönster'))
		assert_equal([lx('segnen|v'), lx('segneen|v')], dic.suffix_lexicals('segnet'))
		dic.close
	end
	

	def test_infix_lexicals
		dic = Dictionary.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal( [lx('information|s'), lx('information|v'), lx('information|e')], dic.suffix_lexicals('informations'))
		dic.close
	end

	
	def test_select_with_suffix
		dic = Dictionary.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal([lx('mauer|s'), lx('mauern|v')], dic.select_with_suffix('mauern'))
		assert_equal([lx('hase|s')], dic.select_with_suffix('hasen'))
		assert_equal([lx('schön|a')], dic.select_with_suffix('schönster'))
		assert_equal([lx('segnen|v')], dic.select_with_suffix('segnet'))
		dic.close
	end
	

	def test_select_with_infix
		dic = Dictionary.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal( [lx('information|s'), lx('information|v'), lx('information|e')], dic.suffix_lexicals('informations'))
		dic.close
	end

	
	def test_find_word
		dic = Dictionary.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal(wd('hasennasen|?'), dic.find_word('hasennasen'))
		assert_equal(wd('hase|IDF', 'hase|s'), dic.find_word('hase'))		
		assert_equal(wd('haseses|IDF', 'hase|s'), dic.find_word('haseses'))
		dic.close
	end
	
end
#
################################################################################



################################################################################
#
#		Grammer
#
class TestGrammar < Test::Unit::TestCase

	def setup
		Lingo.new('lingo.rb', [])
		@dictionary_config = Lingo.config['language/dictionary']
	end

	
	def test_params
		#	Die gleichen Fälle wie bei Dictionary, daher nicht notwendig
	end


	def test_cache
		gra = Grammar.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal(
			wd('informationswissenschaften|KOM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
			gra.find_compositum('informationswissenschaften')
		)
		assert_equal(
			wd('informationswissenschaften|KOM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
			gra.find_compositum('informationswissenschaften')
		)
		assert_equal(
			wd('informationswissenschaften|KOM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
			gra.find_compositum('informationswissenschaften')
		)
		gra.close
	end

	
	def t1est_test_compositum
		gra = Grammar.new({'source'=>['sys-dic']}, @dictionary_config)
		#	hinterer Teil ist ein Wort mit Suffix
		assert_equal([ [5, 6], [lx('hasenbraten|k'), lx('braten|s'), lx('hase|s'), lx('braten|v')] ],
			gra.test_compositum('hasen', '', 'braten', 1, false) 
		)
		#	hinterer Teil ist ein Wort mit Infix ohne Schwanz
		assert_equal([ [5, 7], [lx('nasenlaufen|k'), lx('laufen|s'), lx('nase|s'), lx('laufen|v')] ], 
			gra.test_compositum('nasen', '', 'laufens', 1, false)
		)
		#	hinterer Teil ist ein Wort mit Infix mit Schwanz
		assert_equal([ [5, 7], [lx('nasenlaufens|k'), lx('laufen|s'), lx('nase|s'), lx('laufen|v')] ], 
			gra.test_compositum('nasen', '', 'laufens', 1, true) 
		)
		#	hinterer Teil ist ein Kompositum nach Bindestrich
		assert_equal([ [7, 9, 6], [lx('arrafat-nachfolgebedarf|k'), lx('bedarf|s'), lx('nachfolge|s'), lx('arrafat|x')] ], 
			gra.test_compositum('arrafat', '-', 'nachfolgebedarf', 1, false) 
		)
		#	hinterer Teil ist ein TakeItAsIs nach Bindestrich
		assert_equal([ [9, 7], [lx('nachfolge-arrafat|k'), lx('nachfolge|s'), lx('arrafat|x')] ], 
			gra.test_compositum('nachfolge', '-', 'arrafat', 1, false) 
		)
		#	vorderer Teil ist ein Wort mit Suffix => siehe Hasenbraten
		#	vorderer Teil ist ein Kompositum
		assert_equal([ [6, 5, 6], [lx('morgenonkelmantel|k'), lx('mantel|s'), lx('morgen|s'), lx('onkel|s'), lx('morgen|w')] ], 
			gra.test_compositum('morgenonkel', '', 'mantel', 1, false) 
		)
		#	vorderer Teil ist ein TakeItAsIs vor Bindestrich
		assert_equal([ [7, 10], [lx('arrafat-nachfolger|k'), lx('nachfolger|s'), lx('arrafat|x')] ], 
			gra.test_compositum('arrafat', '-', 'nachfolger', 1, false)
		)
		gra.close
	end

	
	def t1est_permute_compositum
		gra = Grammar.new({'source'=>['sys-dic']}, @dictionary_config)
		#	bindestrichversion
		assert_equal([ [7, 10], [lx('arrafat-nachfolger|k'), lx('nachfolger|s'), lx('arrafat|x')] ], 
			gra.permute_compositum('arrafat-nachfolger', 1, false) 
		)
		#	bindestrichversion zwei-teilig
		assert_equal([ [6, 11], \
			[	lx('cd-rom-technologie|k'), \
				lx('cd-rom|s'), \
				lx('technologie|s')] ], \
			gra.permute_compositum('cd-rom-technologie', 1, false) \
		)
		#	bindestrichversion drei-teilig
		assert_equal([ [6, 7, 11], \
			[	lx('albert-ludwigs-universität|k'), \
				lx('universität|s'), \
				lx('albert|e'), \
				lx('ludwig|e')] ], \
			gra.permute_compositum('albert-ludwigs-universität', 1, false) \
		)
		#	normal mit suggestion
		assert_equal([ [8, 9], \
			[	lx('benutzerforschung|k'), \
				lx('benutzer|s'), \
				lx('forschung|s')] ], \
			gra.permute_compositum('benutzerforschung', 1, false) \
		)
		gra.close
	end

	
	def test_find_compositum
		gra = Grammar.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal( 
			wd('informationswissenschaften|KOM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'), 
			gra.find_compositum('informationswissenschaften') \
		)
		assert_equal( 
			wd('cd-rom-technologie|KOM', 'cd-rom-technologie|k', 'technologie|s+', 'cd-rom|x+'), 
			gra.find_compositum('cd-rom-technologie') 
		)
		assert_equal( 
			wd('albert-ludwigs-universität|KOM', 'albert-ludwigs-universität|k', 'albert|e+', 'ludwig|e+', 'universität|s+'), 
			gra.find_compositum('albert-ludwigs-universität') 
		)
		assert_equal( 
			wd('client-server-system|KOM', 'client-server-system|k', 'client|s+', 'server|s+', 'system|s+'), 
			gra.find_compositum('client-server-system') 
		)
		assert_equal( 
			wd('benutzerforschung|KOM', 'benutzerforschung|k', 'benutzer|s+', 'forschung|s+'),
			gra.find_compositum('benutzerforschung') 
		)
		assert_equal( 
			wd('clustersuche|KOM', 'clustersuche|k', 'cluster|s+', 'suche|s+'), 
			gra.find_compositum('clustersuche') 
		)
		gra.close
	end
	
	
	def test_min_word_size
		gra = Grammar.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal( wd('undsund|?'), gra.find_compositum('undsund'))
		gra.close
	end


	def test_max_parts
		gra = Grammar.new({'source'=>['sys-dic']}, @dictionary_config)
		assert_equal( 
			wd('baumsbaumsbaum|KOM', 'baumsbaumsbaum|k', 'baum|s+'), 
			gra.find_compositum('baumsbaumsbaum') 
		)
		assert_equal( Word.new('baumsbaumsbaumsbaumsbaumsbaum', WA_UNKNOWN), gra.find_compositum('baumsbaumsbaumsbaumsbaumsbaum'))
		gra.close
	end

end
#
################################################################################

