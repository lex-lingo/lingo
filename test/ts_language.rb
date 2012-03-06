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

  def test_report
    lh('tst-syn') { |ds|
      ds['abwickeln']  # source read
      ds['abwickeln']  # cache hit
      ds['regen']      # source read
      ds['nonesens']   # source read, nothing found

      assert_equal({
        'tst-syn: cache hits'     => 1,
        'tst-syn: total requests' => 4,
        'tst-syn: source reads'   => 3,
        'tst-syn: data found'     => 2
      }, ds.report)
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
      assert_equal([lx('aalen|v'), lx('aalen|e')], ds['aalen'])
      assert_equal([lx('abarbeitend|a')], ds['abarbeitend'])
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
      assert_equal([lx('dependenz|y'), lx('unselbstständigkeit|y'), lx('unselbständigkeit|y')], ds['abhängigkeit'])
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

  def test_report
    ld('source' => %w[sys-dic]) { |dic|
      dic.select('abwickeln')  # source read
      dic.select('abwickeln')  # cache hit
      dic.select('regen')      # source read
      dic.select('nonesens')   # source read, nothing found

      assert_equal({
        'sys-dic: total requests' => 4,
        'sys-dic: data found'     => 2,
        'sys-dic: cache hits'     => 1,
        'sys-dic: source reads'   => 3
      }, dic.report)
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

  def test_test_compound
    lg { |gra|
      # hinterer Teil ist ein Wort mit Suffix
      assert_equal([
        [lx('hasenbraten|k'), lx('hase|s'), lx('braten|v')],
        [5, 6], 'sv'], gra.test_compound('hasen', '', 'braten')
      )

      # hinterer Teil ist ein Wort mit Infix ohne Schwanz
      assert_equal([
        [lx('nasenlaufen|k'), lx('nase|s'), lx('laufen|v')],
        [5, 7], 'sv'], gra.test_compound('nasen', '', 'laufens')
      )

      # hinterer Teil ist ein Wort mit Infix mit Schwanz
      assert_equal([
        [lx('nasenlaufens|k'), lx('nase|s'), lx('laufen|v')],
        [5, 7], 'sv'], gra.test_compound('nasen', '', 'laufens', 1, true)
      )

      # hinterer Teil ist ein Kompositum nach Bindestrich
      assert_equal([
        [lx('arrafat-nachfolgebedarf|k'), lx('bedarf|s'), lx('nachfolge|s'), lx('arrafat|x')],
        [7, 9, 6], 'xss'], gra.test_compound('arrafat', '-', 'nachfolgebedarf')
      )

      # hinterer Teil ist ein TakeItAsIs nach Bindestrich
      assert_equal([
        [lx('nachfolge-arrafat|k'), lx('nachfolge|s'), lx('arrafat|x')],
        [9, 7], 'sx'], gra.test_compound('nachfolge', '-', 'arrafat')
      )

      # vorderer Teil ist ein Wort mit Suffix => siehe Hasenbraten
      # vorderer Teil ist ein Kompositum
      assert_equal([
        [lx('morgenonkelmantel|k'), lx('mantel|s'), lx('morgen|s'), lx('onkel|s'), lx('morgen|w')],
        [6, 5, 6], 'sss'], gra.test_compound('morgenonkel', '', 'mantel')
      )

      # vorderer Teil ist ein TakeItAsIs vor Bindestrich
      assert_equal([
        [lx('arrafat-nachfolger|k'), lx('nachfolger|s'), lx('arrafat|x')],
        [7, 10], 'xs'], gra.test_compound('arrafat', '-', 'nachfolger')
      )
    }
  end

  def test_permute_compound
    lg { |gra|
      # bindestrichversion
      assert_equal([
        [lx('arrafat-nachfolger|k'), lx('nachfolger|s'), lx('arrafat|x')],
        [7, 10], 'xs'], gra.permute_compound('arrafat-nachfolger')
      )

      # bindestrichversion zwei-teilig
      assert_equal([
        [lx('cd-rom-technologie|k'), lx('cd-rom|s'), lx('technologie|s')],
        [6, 11], 'ss'], gra.permute_compound('cd-rom-technologie')
      )

      # bindestrichversion drei-teilig
      assert_equal([
        [lx('albert-ludwigs-universität|k'), lx('universität|s'), lx('albert|e'), lx('ludwig|e')],
        [6, 7, 11], 'ees'], gra.permute_compound('albert-ludwigs-universität')
      )

      # normal mit suggestion
      assert_equal([
        [lx('benutzerforschung|k'), lx('erforschung|s'), lx('benutzen|v')],
        [6, 11], 'vs'], gra.permute_compound('benutzerforschung')
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
        wd('benutzerforschung|KOM', 'benutzerforschung|k', 'erforschung|s+', 'benutzen|v+'),
        gra.find_compound('benutzerforschung')
      )
      assert_equal(
        wd('clustersuche|KOM', 'clustersuche|k', 'cluster|s+', 'suche|s+', 'suchen|v+'),
        gra.find_compound('clustersuche')
      )
    }
  end

  def test_min_word_size
    lg { |gra| assert_equal( wd('undsund|?'), gra.find_compound('undsund')) }
  end

  def test_max_parts
    lg { |gra|
      assert_equal(wd('baumsbaumsbaum|KOM', 'baumsbaumsbaum|k', 'baum|s+'), gra.find_compound('baumsbaumsbaum'))
      assert_equal(wd('baumsbaumsbaumsbaumsbaumsbaum|?'), gra.find_compound('baumsbaumsbaumsbaumsbaumsbaum'))
    }
  end

  def lg(&block)
    Lingo::Language::Grammar.open({ 'source' => %w[sys-dic] }, @lingo, &block)
  end

end
