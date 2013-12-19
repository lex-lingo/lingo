# encoding: utf-8

require_relative 'test_helper'

class TestLexicalHash < LingoTestCase

  def setup
    @lingo = Lingo.new
    @database_config = @lingo.config['language/dictionary/databases']
  end

  def teardown
    cleanup_store
  end

  def test_params
    old_stderr, $stderr = $stderr, StringIO.new('')

    assert_raise(Lingo::NoDatabaseConfigError) {
      Lingo::Language::LexicalHash.new('nonsens', @lingo)
    }
  ensure
    $stderr = old_stderr
  end

  # TODO: Crypt testen...

  def test_cache
    lh('sys-dic') { |ds|
      assert_equal([lx('regen|s'), lx('regen|v'), lx('rege|a')], ds['regen'])
      assert_equal([lx('regen|s'), lx('regen|v'), lx('rege|a')], ds['regen'])
      assert_equal([lx('regen|s'), lx('regen|v'), lx('rege|a')], ds['regen'])
    }
  end

  def test_auto_create
    txt_file = @database_config[id = 'tst-sgw']['name']

    lh(id) { |ds| assert_equal([lx('substantiv|s')], ds['substantiv']) }

    # Keine Store-Datei vorhanden, nur Text vorhanden
    File.delete(*Dir["#{Lingo.find(:store, txt_file)}.*"])
    lh(id) { |ds| assert_equal([lx('substantiv|s')], ds['substantiv']) }

    # Store vorhanden, aber Text ist neuer
    lh(id) { |ds| assert_equal([lx('substantiv|s')], ds['substantiv']) }
  end

  def test_singleword
    lh('tst-sgw') { |ds|
      assert_equal([lx('substantiv|s')], ds['substantiv'])
      assert_equal([lx('mehr wort gruppe|s')], ds['mehr wort gruppe'])
      assert_equal(nil, ds['nicht vorhanden'])
    }
  end

  def test_keyvalue
    lh('sys-mul') { |ds|
      assert_equal([lx('abelscher ring ohne nullteiler|m')], ds['abelscher ring ohne nullteiler'])
      assert_equal(['*4'], ds['abelscher ring ohne'])
      assert_equal([lx('alleinreisende frau|m')], ds['alleinreisend frau'])
      assert_equal([lx('abschaltbarer leistungshalbleiter|m')], ds['abschaltbar leistungshalbleiter'])
      assert_equal(nil, ds['abschaltbarer leistungshalbleiter'])
    }
  end

  def test_wordclass
    lh('sys-dic') { |ds|
      assert_equal([lx('a-dur|s')], ds['a-dur'])
      assert_equal([lx('aalen|e'), lx('aalen|v')], ds['aalen'])
      assert_equal([lx('abarbeitend|a')], ds['abarbeitend'])
    }
  end

  def test_wordclass_gender
    lh('tst-gen') { |ds|
      assert_equal([lx('substantiv|a'), lx('substantiv|s|n')], ds['substantiv'])
      assert_equal([lx('mehr|w'), lx('mehr|s|n'), lx('mehren|v')], ds['mehr'])
      assert_equal([lx('wort|s|n')], ds['wort'])
      assert_equal([lx('gruppe|s|f')], ds['gruppe'])
      assert_equal([lx('modul|s|m'), lx('modul|s|n')], ds['modul'])
      assert_equal([lx('nock|s|f'), lx('nock|s|m'), lx('nock|s|n'), lx('nocke|s|f'), lx('nocken|s|m')], ds['nocken'])
      assert_equal([lx('albern|a'), lx('albern|v')], ds['albern'])
      assert_equal([lx('fortuna|e|f'), lx('fortuna|s|f')], ds['fortuna'])
    }
  end

  def test_case
    lh('sys-dic') { |ds|
      assert_equal([lx('abänderung|s')], ds['abänderung'])
      assert_equal([lx('abänderung|s')], ds['Abänderung'])
      assert_equal([lx('abänderung|s')], ds['ABÄNDERUNG'])
    }
  end

  def test_multivalue
    lh('sys-syn') { |ds|
      assert_equal([lx('abbau <chemie>|y'), lx('chemische abbaureaktion|y'), lx('chemischer abbau|y'), lx('photochemischer abbau|y')], ds['abbaureaktion'])
      assert_equal([lx('dependenz|y'), lx('unselbständigkeit|y'), lx('unselbstständigkeit|y')], ds['abhängigkeit'])
    }
  end

  def lh(id, &block)
    Lingo::Language::LexicalHash.open(id, @lingo, &block)
  end

end

class TestDictionary < LingoTestCase

  def setup
    @lingo = Lingo.new
  end

  def test_params
    # Keine Sprach-Konfiguration angegeben
    #assert_raise(RuntimeError) {
    #  Lingo::Language::Dictionary.new({ 'source' => %w[sys-dic] }, @lingo)
    #}

    # Falsche Parameter angegeben (Pflichtparameter ohne Defaultwert)
    assert_raise(ArgumentError) {
      Lingo::Language::Dictionary.new({ 'course' => %w[sys-dic] }, @lingo)
    }
  end

  def test_cache
    ld('source' => %w[sys-dic]) { |dic|
      assert_equal([lx('nase|s')], dic.select('nase'))
      assert_equal([lx('nase|s')], dic.select('nase'))
      assert_equal([lx('nase|s')], dic.select('nase'))
    }
  end

  def test_select_one_source
    ld('source' => %w[sys-dic]) { |dic|
      assert_equal([lx('nase|s')], dic.select('nase'))
      assert_equal([lx('nase|s')], dic.select('NASE'))
      assert_equal([], dic.select('hasennasen'))
    }
  end

  def test_select_two_sources_mode_first
    ld('source' => %w[sys-dic tst-dic], 'mode' => 'first') { |dic|
      # in keiner Quelle vorhanden
      assert_equal([], dic.select('hasennasen'))
      # nur in erster Quelle vorhanden
      assert_equal([lx('knaller|s')], dic.select('knaller'))
      # nur in zweiter Quelle vorhanden
      assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
      # in beiden Quellen vorhanden
      assert_equal([lx('a-dur|s')], dic.select('a-dur'))
    }
  end

  def test_select_two_sources_mode_first_flipped
    ld('source' => %w[tst-dic sys-dic], 'mode' => 'first') { |dic|
      # in keiner Quelle vorhanden
      assert_equal([], dic.select('hasennasen'))
      # nur in erster Quelle vorhanden
      assert_equal([lx('knaller|s')], dic.select('knaller'))
      # nur in zweiter Quelle vorhanden
      assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
      # in beiden Quellen vorhanden
      assert_equal([lx('b-dur|s')], dic.select('a-dur'))
    }
  end

  def test_select_two_sources_mode_all
    ld('source' => %w[sys-dic tst-dic], 'mode' => 'all') { |dic|
      # in keiner Quelle vorhanden
      assert_equal([], dic.select('hasennasen'))
      # nur in erster Quelle vorhanden
      assert_equal([lx('knaller|s')], dic.select('knaller'))
      # nur in zweiter Quelle vorhanden
      assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
      # in beiden Quellen vorhanden
      assert_equal([lx('a-dur|s'), lx('b-dur|s')], dic.select('a-dur'))
      assert_equal([lx('aas|s')], dic.select('aas'))
    }
  end

  def test_select_two_sources_mode_default
    ld('source' => %w[sys-dic tst-dic]) { |dic|
      # in keiner Quelle vorhanden
      assert_equal([], dic.select('hasennasen'))
      # nur in erster Quelle vorhanden
      assert_equal([lx('knaller|s')], dic.select('knaller'))
      # nur in zweiter Quelle vorhanden
      assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
      assert_equal([lx('wirkungsort|s'), lx('wirkung|s+'), lx('ort|s+')], dic.select('wirkungsort'))
      # in beiden Quellen vorhanden
      assert_equal([lx('a-dur|s'), lx('b-dur|s')], dic.select('a-dur'))
      assert_equal([lx('aas|s')], dic.select('aas'))
    }
  end

  def test_suffix_lexicals
    ld('source' => %w[sys-dic]) { |dic|
      assert_equal([lx('mau|s'), lx('mauer|s')], dic.suffix_lexicals('mauern'))
      assert_equal([lx('hasen|s'), lx('hasen|v'), lx('hasen|e')], dic.suffix_lexicals('hasens'))
      assert_equal([lx('schönst|s'), lx('schön|a'), lx('schönst|a')], dic.suffix_lexicals('schönster'))
      assert_equal([lx('segnen|v'), lx('segneen|v')], dic.suffix_lexicals('segnet'))
    }
  end

  def test_infix_lexicals
    ld('source' => %w[sys-dic]) { |dic|
      assert_equal( [lx('information|s'), lx('information|v'), lx('information|e')], dic.suffix_lexicals('informations'))
    }
  end

  def test_select_with_suffix
    ld('source' => %w[sys-dic]) { |dic|
      assert_equal([lx('mauern|v')], dic.select_with_suffix('mauern'))
      assert_equal([lx('hase|s')], dic.select_with_suffix('hasen'))
      assert_equal([lx('schön|a')], dic.select_with_suffix('schönster'))
      assert_equal([lx('segnen|v')], dic.select_with_suffix('segnet'))
    }
  end

  def test_select_with_infix
    ld('source' => %w[sys-dic]) { |dic|
      assert_equal( [lx('information|s'), lx('information|v'), lx('information|e')], dic.suffix_lexicals('informations'))
    }
  end

  def test_find_word
    ld('source' => %w[sys-dic]) { |dic|
      assert_equal(wd('hasennasen|?'), dic.find_word('hasennasen'))
      assert_equal(wd('hase|IDF', 'hase|s'), dic.find_word('hase'))
      assert_equal(wd('haseses|IDF', 'hase|s'), dic.find_word('haseses'))
    }
  end

  def ld(cfg, &block)
    Lingo::Language::Dictionary.open(cfg, @lingo, &block)
  end

end

class TestGrammar < LingoTestCase

  def setup
    @lingo = Lingo.new
  end

  def test_params
    # Die gleichen Fälle wie bei Dictionary, daher nicht notwendig
  end

  def test_cache
    lg { |gra|
      assert_equal(
        wd('informationswissenschaften|KOM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
        gra.find_compound('informationswissenschaften')
      )
      assert_equal(
        wd('informationswissenschaften|KOM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
        gra.find_compound('informationswissenschaften')
      )
      assert_equal(
        wd('informationswissenschaften|KOM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
        gra.find_compound('informationswissenschaften')
      )
    }
  end

  def test_find_compound
    lg { |gra|
      assert_equal(
        wd('informationswissenschaften|KOM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
        gra.find_compound('informationswissenschaften')
      )

      assert_equal(
        wd('cd-rom-technologie|KOM', 'cd-rom-technologie|k', 'cd-rom|s+', 'technologie|s+'),
        gra.find_compound('cd-rom-technologie')
      )

      assert_equal(
        wd('albert-ludwigs-universität|KOM', 'albert-ludwigs-universität|k', 'albert|e+', 'ludwig|e+', 'universität|s+'),
        gra.find_compound('albert-ludwigs-universität')
      )

      assert_equal(
        wd('client-server-system|KOM', 'client-server-system|k', 'client|s+', 'server|s+', 'system|s+'),
        gra.find_compound('client-server-system')
      )

      assert_equal(
        wd('benutzerforschung|KOM', 'benutzerforschung|k', 'benutzen|v+', 'erforschung|s+'),
        gra.find_compound('benutzerforschung')
      )

      assert_equal(
        wd('clustersuche|KOM', 'clustersuche|k', 'cluster|s+', 'suche|s+', 'suchen|v+'),
        gra.find_compound('clustersuche')
      )

      assert_equal(
        wd('titelkatalogstitel|KOM', 'titelkatalogstitel|k', 'titel|s+', 'katalog|s+', 'titel|s+'),
        gra.find_compound('titelkatalogstitel')
      )

      assert_equal(
        wd('titelkatalogstiteltitel|KOM', 'titelkatalogstiteltitel|k', 'titel|s+', 'katalog|s+', 'titel|s+', 'titel|s+'),
        gra.find_compound('titelkatalogstiteltitel')
      )

      assert_equal(
        wd('titelbestandsbestände|KOM', 'titelbestandsbestand|k', 'titel|s+', 'bestand|s+', 'bestand|s+', 'bestehen|v+'),
        gra.find_compound('titelbestandsbestände')
      )

      # hinterer Teil ist ein Wort mit Suffix
      assert_equal(
        wd('hasenbraten|KOM', 'hasenbraten|k', 'hase|s+', 'braten|v+'),
        gra.find_compound('hasenbraten')
      )

      # hinterer Teil ist ein Wort mit Infix ohne Schwanz
      assert_equal(
        wd('nasenlaufen|KOM', 'nasenlaufen|k', 'nase|s+', 'laufen|v+'),
        gra.find_compound('nasenlaufen')
      )

      # hinterer Teil ist ein Wort mit Infix mit Schwanz
      assert_equal(
        wd('nasenlaufens|KOM', 'nasenlaufen|k', 'nase|s+', 'laufen|v+'),
        gra.find_compound('nasenlaufens')
      )

      # hinterer Teil ist ein Kompositum nach Bindestrich
      assert_equal(
        wd('arrafat-nachfolgebedarf|KOM', 'arrafat-nachfolgebedarf|k', 'arrafat|x+', 'nachfolge|s+', 'bedarf|s+'),
        gra.find_compound('arrafat-nachfolgebedarf')
      )

      # hinterer Teil ist ein TakeItAsIs nach Bindestrich
      assert_equal(
        wd('nachfolge-arrafat|KOM', 'nachfolge-arrafat|k', 'nachfolge|s+', 'arrafat|x+'),
        gra.find_compound('nachfolge-arrafat')
      )

      # vorderer Teil ist ein Wort mit Suffix => siehe Hasenbraten
      # vorderer Teil ist ein Kompositum
      assert_equal(
        wd('morgenonkelmantel|KOM', 'morgenonkelmantel|k', 'morgen|w+', 'morgen|s+', 'onkel|s+', 'mantel|s+'),
        gra.find_compound('morgenonkelmantel')
      )

      # vorderer Teil ist ein TakeItAsIs vor Bindestrich / bindestrichversion
      assert_equal(
        wd('arrafat-nachfolger|KOM', 'arrafat-nachfolger|k', 'arrafat|x+', 'nachfolger|s+'),
        gra.find_compound('arrafat-nachfolger')
      )

      # bindestrichversion zwei-teilig
      assert_equal(
        wd('cd-rom-technologie|KOM', 'cd-rom-technologie|k', 'cd-rom|s+', 'technologie|s+'),
        gra.find_compound('cd-rom-technologie')
      )

      # bindestrichversion drei-teilig
      assert_equal(
        wd('albert-ludwigs-universität|KOM', 'albert-ludwigs-universität|k', 'albert|e+', 'ludwig|e+', 'universität|s+'),
        gra.find_compound('albert-ludwigs-universität')
      )

      # normal mit suggestion
      assert_equal(
        wd('benutzerforschung|KOM', 'benutzerforschung|k', 'benutzen|v+', 'erforschung|s+'),
        gra.find_compound('benutzerforschung')
      )
    }
  end

  def test_head
    lg { |gra|
      assert_equal(
        wd('suche|-', 'suche|s', 'suchen|v'),
        gra.find_compound('clustersuche').head
      )

      assert_equal(
        wd('titel|-', 'titel|s'),
        gra.find_compound('titelkatalogstitel').head
      )

      assert_equal(
        wd('titel|-', 'titel|s'),
        gra.find_compound('titelkatalogstiteltitel').head
      )

      assert_equal(
        wd('bestand|-', 'bestand|s', 'bestehen|v'),
        gra.find_compound('titelbestandsbestände').head
      )

      assert_nil(gra.find_compound('bibliothekskatalög').head)
    }
  end

  def test_min_word_size
    lg { |gra| assert_equal( wd('undsund|?'), gra.find_compound('undsund')) }
  end

  def test_max_parts
    lg { |gra|
      assert_equal(wd('baumsbaumsbaum|KOM', 'baumsbaumsbaum|k', 'baum|s+', 'baum|s+', 'baum|s+'), gra.find_compound('baumsbaumsbaum'))
      assert_equal(wd('baumsbaumsbaumsbaumsbaumsbaum|?'), gra.find_compound('baumsbaumsbaumsbaumsbaumsbaum'))
    }
  end

  def lg(&block)
    Lingo::Language::Grammar.open({ 'source' => %w[sys-dic] }, @lingo, &block)
  end

end
