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
#    Database Test-Suite
class TestDatabase < Test::Unit::TestCase

  def setup
    Lingo.new('lingo.rb', [])
    
    @singleword = <<END_OF_TEXT
Wort1
Wort2
Wort2
juristische Personen
höher schneller weiter
höher schneller weiter größer
ganz großer und blöder quatsch
ganz großer und blöder mist
ganz großer und blöder schwach sinn
END_OF_TEXT

    @keyvalue = <<END_OF_TEXT
Wort1*Projektion1
Wort2*Projektion2
Wort3*Projektion3
Wort4*
Wort1*Projektion4
Wort1 * Projektion5
Mehr Wort Satz*Pro Jeck Zion 1
Mehr Wort Satz*Pro Jeck Zion 2
Albert Einstein*Einstein, Albert
END_OF_TEXT

    @wordclass = <<END_OF_TEXT
Wort1=Projektion1#h
Wort2=Projektion2#i
Wort3=Projektion3#e
Wort1=Projektion4 #e
Wort1=#s
Wort2=
END_OF_TEXT
  end


  def test_singleword
    expect = {
      'wort1'=>'#s',
      'wort2'=>'#s',
      'juristische personen'=>'#m',
      'höher schneller weiter'=>'#m',
      'höher schneller weiter größer'=>'#m',
      'ganz großer und blöder quatsch'=>'#m',
      'ganz großer und blöder mist'=>'#m',
      'ganz großer und blöder schwach sinn'=>'#m'
    }
    compare( 'tst-sw1', @singleword, expect )
  end

  
  def test_singleword_defwc
    expect = {
      'wort1'=>'#*',
      'wort2'=>'#*',
      'juristische personen'=>'#m',
      'höher schneller weiter'=>'#m',
      'höher schneller weiter größer'=>'#m',
      'ganz großer und blöder quatsch'=>'#m',
      'ganz großer und blöder mist'=>'#m',
      'ganz großer und blöder schwach sinn'=>'#m'
    }
    compare( 'tst-sw2', @singleword, expect )
  end

  
  def test_singleword_uselex
    expect = {
      'wort1'=>'#s',
      'wort2'=>'#s',
      'ganz groß und blöd mist'=>'ganz großer und blöder mist#m',
      'juristisch person'=>'juristische personen#m',
      'höher schnell weit'=>'*4|höher schneller weiter#m',
      'ganz groß und blöd quatsch'=>'ganz großer und blöder quatsch#m',
      'höher schnell weit größer'=>'höher schneller weiter größer#m',
      'ganz groß und blöd schwach sinn'=>'ganz großer und blöder schwach sinn#m',
      'ganz groß und'=>'*5|*6'
    }
    compare( 'tst-sw3', @singleword, expect )
  end


  def test_singleword_crypt
    expect = {
      "45ce936374c89e8f09b9fb4f702801601c5a87d9"=>"4b0e",
      "3ac77f4e6fe2da8828542589ccbd6378de88649a"=>"5108",
      "81463f9c7e0ad40e329e83d3358232851d50ed9a"=>"4d08",
      "8da4a0c30c912543be2d88da64c0192e577efa9d"=>"1107",
      "5d890032a9ec8b9a31974d65be8a7adfca510f27"=>"571e",
      "a28b4ca84ac08aeef4e420445f94f632ad010a30"=>"1207",
      "0582f43880cb2e6ce8a7f316a1031e3ff150794f"=>"4d03",
      "196b884889c5c8356b9c9c799b9a36024f5c1224"=>"5108"
    }
    compare( 'tst-sw4', @singleword, expect )

    expect = {
      'wort1'=>'#s',
      'wort2'=>'#s',
      'juristische personen'=>'#m',
      'höher schneller weiter'=>'#m',
      'höher schneller weiter größer'=>'#m',
      'ganz großer und blöder quatsch'=>'#m',
      'ganz großer und blöder mist'=>'#m',
      'ganz großer und blöder schwach sinn'=>'#m'
    }
    dbm = DbmFile.new( 'tst-sw4' )
    dbm.open
    expect.each_pair { |key, val| assert_equal( [val], dbm[key] ) }
    dbm.close
  end


  def test_keyvalue
    expect = {
      'wort1'=>'projektion1#?|projektion4#?|projektion5#?',
      'wort2'=>'projektion2#?',
      'wort3'=>'projektion3#?',
      'mehr wort satz'=>'pro jeck zion 1#?|pro jeck zion 2#?',
      'albert einstein'=>'einstein, albert#?'
    }
    compare( 'tst-kv1', @keyvalue, expect )
  end

  
  def test_keyvalue_separator
    expect = {
      'wort1'=>'projektion1#?|projektion4#?|projektion5#?',
      'wort2'=>'projektion2#?',
      'wort3'=>'projektion3#?',
      'mehr wort satz'=>'pro jeck zion 1#?|pro jeck zion 2#?',
      'albert einstein'=>'einstein, albert#?'
    }
    compare( 'tst-kv2', @keyvalue, expect )
  end

  
  def test_keyvalue_defwc
    expect = {
      'wort1'=>'projektion1#s|projektion4#s|projektion5#s',
      'wort2'=>'projektion2#s',
      'wort3'=>'projektion3#s',
      'mehr wort satz'=>'pro jeck zion 1#s|pro jeck zion 2#s',
      'albert einstein'=>'einstein, albert#s'
    }
    compare( 'tst-kv3', @keyvalue, expect )
  end


  def test_wordclass
    txtfile = %q{
      Wort1=Projektion1#h
      Wort2=Projektion2#i
      Wort3=Projektion3#e
      Wort1=Projektion4 #e
      Wort1=#s
      Wort2=
    }.delete( "\t" )
    expect = {
      'wort1'=>'projektion1#h|projektion4#e',
      'wort2'=>'projektion2#i',
      'wort3'=>'projektion3#e'
    }
    compare( 'tst-wc1', txtfile, expect )
  end

  
  def test_multivalue
    txtfile = %q{
      Hasen;Nasen;Vasen;Rasen
      Gold;Edelmetall;Mehrwert
      Rasen;Gras;Grüne Fläche
      Rasen;Rennen;Wettrennen
    }.delete( "\t" )
    expect = {
      '^0'=>'hasen|nasen|rasen|vasen',
      '^1'=>'edelmetall|gold|mehrwert',
      '^2'=>'gras|grüne fläche|rasen',
      '^3'=>'rasen|rennen|wettrennen',    
      'hasen'=>'^0',
      'nasen'=>'^0',
      'rasen'=>'^0|^2|^3',
      'vasen'=>'^0',
      'edelmetall'=>'^1',
      'gold'=>'^1',
      'mehrwert'=>'^1',
      'gras'=>'^2',
      'grüne fläche'=>'^2',
      'wettrennen'=>'^3',
      'rennen'=>'^3'
    }
    compare( 'tst-mv1', txtfile, expect )
  end


  def test_multikey
    txtfile = %q{
      Hasen;Nasen;Vasen;Rasen
      Gold;Edelmetall;Mehrwert
    }.delete( "\t" )
    expect = {
      'nasen'=>'hasen',
      'vasen'=>'hasen',
      'rasen'=>'hasen',
      'edelmetall'=>'gold',
      'mehrwert'=>'gold',
    }
    compare( 'tst-mk1', txtfile, expect )
  end

  
  def compare( id, input, output )
    txtfile = Lingo.config['language/dictionary/databases/' + id + '/name']
    File.open( txtfile, 'w' ) { |file| file.puts input, ' ' * id[-1] }
    dbm = DbmFile.new( id )
    dbm.open
    store = dbm.to_h
    dbm.close
    store.delete( SYS_KEY )
    assert_equal( output, store )
  end

end
#
################################################################################
