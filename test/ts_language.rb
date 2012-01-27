# encoding: utf-8

require_relative 'test_helper'

class TestLexicalHash < LingoTestCase

  LH = Lingo::Language::LexicalHash

  def setup
    @lingo = Lingo.new
    @database_config = @lingo.config['language/dictionary/databases']
  end

  def teardown
    cleanup_store
  end

  def test_params
    old_stderr, $stderr = $stderr, StringIO.new('')

    # Datenquelle nicht in Konfiguration enthalten
    assert_raise(Lingo::NoDatabaseConfigError) { LH.new('nonsens', @lingo) }
  ensure
    $stderr = old_stderr
  end

  # TODO: Crypt testen...

  def test_cache
    ds = LH.new('sys-dic', @lingo)
    assert_equal([lx('regen|s'), lx('regen|v'), lx('rege|a')], ds['regen'])
    assert_equal([lx('regen|s'), lx('regen|v'), lx('rege|a')], ds['regen'])
    assert_equal([lx('regen|s'), lx('regen|v'), lx('rege|a')], ds['regen'])
    ds.close
  end

  def test_report
    ds = LH.new('tst-syn', @lingo)
    ds['abwickeln']    # source read
    ds['abwickeln']    # cache hit
    ds['regen']        # source read
    ds['nonesens']     # source read, nothing found

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

    ds = LH.new('tst-sgw', @lingo)
    assert_equal([lx('substantiv|s')], ds['substantiv'])
    ds.close

    # Keine Store-Datei vorhanden, nur Text vorhanden
    File.delete(*Dir["#{Lingo.find(:store, txt_file)}.*"])
    ds = LH.new('tst-sgw', @lingo)
    assert_equal([lx('substantiv|s')], ds['substantiv'])
    ds.close

    # Store vorhanden, aber Text ist neuer
    ds = LH.new('tst-sgw', @lingo)
    assert_equal([lx('substantiv|s')], ds['substantiv'])
    ds.close
  end

  def test_singleword
    ds = LH.new('tst-sgw', @lingo)
    assert_equal([lx('substantiv|s')], ds['substantiv'])
    assert_equal([lx('mehr wort gruppe|s')], ds['mehr wort gruppe'])
    assert_equal(nil, ds['nicht vorhanden'])
    ds.close
  end

  def test_keyvalue
    ds = LH.new('sys-mul', @lingo)
    assert_equal([lx('abelscher ring ohne nullteiler|m')], ds['abelscher ring ohne nullteiler'])
    assert_equal(['*4'], ds['abelscher ring ohne'])
    assert_equal([lx('alleinreisende frau|m')], ds['alleinreisend frau'])
    assert_equal([lx('abschaltbarer leistungshalbleiter|m')], ds['abschaltbar leistungshalbleiter'])
    assert_equal(nil, ds['abschaltbarer leistungshalbleiter'])
    ds.close
  end

  def test_wordclass
    ds = LH.new('sys-dic', @lingo)
    assert_equal([lx('a-dur|s')], ds['a-dur'])
    assert_equal([lx('aalen|v'), lx('aalen|e')], ds['aalen'])
    assert_equal([lx('abarbeitend|a')], ds['abarbeitend'])
    ds.close
  end

  def test_case
    ds = LH.new('sys-dic', @lingo)
    assert_equal([lx('abänderung|s')], ds['abänderung'])
    assert_equal([lx('abänderung|s')], ds['Abänderung'])
    assert_equal([lx('abänderung|s')], ds['ABÄNDERUNG'])
    ds.close
  end

  def test_multivalue
    ds = LH.new('sys-syn', @lingo)
    assert_equal([lx('abbau <chemie>|y'), lx('chemische abbaureaktion|y'), lx('chemischer abbau|y'), lx('photochemischer abbau|y')], ds['abbaureaktion'])
    assert_equal([lx('dependenz|y'), lx('unselbstständigkeit|y'), lx('unselbständigkeit|y')], ds['abhängigkeit'])
    ds.close
  end

end

class TestDictionary < LingoTestCase

  LD = Lingo::Language::Dictionary

  def setup
    @lingo = Lingo.new
  end

  def test_params
    # Keine Sprach-Konfiguration angegeben
   #assert_raise(RuntimeError) { LD.new({'source'=>['sys-dic']}, @lingo) }
    # Falsche Parameter angegeben (Pflichtparameter ohne Defaultwert)
    assert_raise(ArgumentError) { LD.new({'course'=>['sys-dic']}, @lingo) }
  end

  def test_cache
    dic = LD.new({'source'=>['sys-dic']}, @lingo)
    assert_equal([lx('nase|s')], dic.select('nase'))
    assert_equal([lx('nase|s')], dic.select('nase'))
    assert_equal([lx('nase|s')], dic.select('nase'))
    dic.close
  end

  def test_report
    dic = LD.new({'source'=>['sys-dic']}, @lingo)
    dic.select('abwickeln')    # source read
    dic.select('abwickeln')    # cache hit
    dic.select('regen')        # source read
    dic.select('nonesens')     # source read, nothing found

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
    dic = LD.new({'source'=>['sys-dic']}, @lingo)
    assert_equal([lx('nase|s')], dic.select('nase'))
    assert_equal([lx('nase|s')], dic.select('NASE'))
    assert_equal([], dic.select('hasennasen'))
    dic.close
  end

  def test_select_two_sources_mode_first
    dic = LD.new({'source'=>['sys-dic', 'tst-dic'], 'mode'=>'first'}, @lingo)
    # in keiner Quelle vorhanden
    assert_equal([], dic.select('hasennasen'))
    # nur in erster Quelle vorhanden
    assert_equal([lx('knaller|s')], dic.select('knaller'))
    # nur in zweiter Quelle vorhanden
    assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
    # in beiden Quellen vorhanden
    assert_equal([lx('a-dur|s')], dic.select('a-dur'))
    dic.close
  end

  def test_select_two_sources_mode_first_flipped
    dic = LD.new({'source'=>['tst-dic','sys-dic'], 'mode'=>'first'}, @lingo)
    # in keiner Quelle vorhanden
    assert_equal([], dic.select('hasennasen'))
    # nur in erster Quelle vorhanden
    assert_equal([lx('knaller|s')], dic.select('knaller'))
    # nur in zweiter Quelle vorhanden
    assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
    # in beiden Quellen vorhanden
    assert_equal([lx('b-dur|s')], dic.select('a-dur'))
    dic.close
  end

  def test_select_two_sources_mode_all
    dic = LD.new({'source'=>['sys-dic','tst-dic'], 'mode'=>'all'}, @lingo)
    # in keiner Quelle vorhanden
    assert_equal([], dic.select('hasennasen'))
    # nur in erster Quelle vorhanden
    assert_equal([lx('knaller|s')], dic.select('knaller'))
    # nur in zweiter Quelle vorhanden
    assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
    # in beiden Quellen vorhanden
    assert_equal([lx('a-dur|s'), lx('b-dur|s')], dic.select('a-dur'))
    assert_equal([lx('aas|s')], dic.select('aas'))
    dic.close
  end

  def test_select_two_sources_mode_default
    dic = LD.new({'source'=>['sys-dic','tst-dic']}, @lingo)
    # in keiner Quelle vorhanden
    assert_equal([], dic.select('hasennasen'))
    # nur in erster Quelle vorhanden
    assert_equal([lx('knaller|s')], dic.select('knaller'))
    # nur in zweiter Quelle vorhanden
    assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
    # in beiden Quellen vorhanden
    assert_equal([lx('a-dur|s'), lx('b-dur|s')], dic.select('a-dur'))
    assert_equal([lx('aas|s')], dic.select('aas'))
    dic.close
  end

  def test_suffix_lexicals
    dic = LD.new({'source'=>['sys-dic']}, @lingo)
    assert_equal([lx('mau|s'), lx('mauer|s')], dic.suffix_lexicals('mauern'))
    assert_equal([lx('hasen|s'), lx('hasen|v'), lx('hasen|e')], dic.suffix_lexicals('hasens'))
    assert_equal([lx('schönst|s'), lx('schön|a'), lx('schönst|a')], dic.suffix_lexicals('schönster'))
    assert_equal([lx('segnen|v'), lx('segneen|v')], dic.suffix_lexicals('segnet'))
    dic.close
  end

  def test_infix_lexicals
    dic = LD.new({'source'=>['sys-dic']}, @lingo)
    assert_equal( [lx('information|s'), lx('information|v'), lx('information|e')], dic.suffix_lexicals('informations'))
    dic.close
  end

  def test_select_with_suffix
    dic = LD.new({'source'=>['sys-dic']}, @lingo)
    assert_equal([lx('mauern|v')], dic.select_with_suffix('mauern'))
    assert_equal([lx('hase|s')], dic.select_with_suffix('hasen'))
    assert_equal([lx('schön|a')], dic.select_with_suffix('schönster'))
    assert_equal([lx('segnen|v')], dic.select_with_suffix('segnet'))
    dic.close
  end

  def test_select_with_infix
    dic = LD.new({'source'=>['sys-dic']}, @lingo)
    assert_equal( [lx('information|s'), lx('information|v'), lx('information|e')], dic.suffix_lexicals('informations'))
    dic.close
  end

  def test_find_word
    dic = LD.new({'source'=>['sys-dic']}, @lingo)
    assert_equal(wd('hasennasen|?'), dic.find_word('hasennasen'))
    assert_equal(wd('hase|IDF', 'hase|s'), dic.find_word('hase'))
    assert_equal(wd('haseses|IDF', 'hase|s'), dic.find_word('haseses'))
    dic.close
  end

end

class TestGrammar < LingoTestCase

  LG = Lingo::Language::Grammar

  def setup
    @lingo = Lingo.new
  end

  def test_params
    # Die gleichen Fälle wie bei Dictionary, daher nicht notwendig
  end

  def test_cache
    gra = LG.new({'source'=>['sys-dic']}, @lingo)
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

  def test_test_compositum
    gra = LG.new({'source'=>['sys-dic']}, @lingo)

    # hinterer Teil ist ein Wort mit Suffix
    assert_equal([
      [lx('hasenbraten|k'), lx('hase|s'), lx('braten|v')],
      [5, 6],
      'sv'
    ],
      gra.test_compositum('hasen', '', 'braten', 1, false)
    )

    # hinterer Teil ist ein Wort mit Infix ohne Schwanz
    assert_equal([
      [lx('nasenlaufen|k'), lx('nase|s'), lx('laufen|v')],
      [5, 7],
      'sv'
    ],
      gra.test_compositum('nasen', '', 'laufens', 1, false)
    )

    # hinterer Teil ist ein Wort mit Infix mit Schwanz
    assert_equal([
      [lx('nasenlaufens|k'), lx('nase|s'), lx('laufen|v')],
      [5, 7],
      'sv'
    ],
      gra.test_compositum('nasen', '', 'laufens', 1, true)
    )

    # hinterer Teil ist ein Kompositum nach Bindestrich
    assert_equal([
      [lx('arrafat-nachfolgebedarf|k'), lx('bedarf|s'), lx('nachfolge|s'), lx('arrafat|x')],
      [7, 9, 6],
      'xss'
    ],
      gra.test_compositum('arrafat', '-', 'nachfolgebedarf', 1, false)
    )

    # hinterer Teil ist ein TakeItAsIs nach Bindestrich
    assert_equal([
      [lx('nachfolge-arrafat|k'), lx('nachfolge|s'), lx('arrafat|x')],
      [9, 7],
      'sx'
    ],
      gra.test_compositum('nachfolge', '-', 'arrafat', 1, false)
    )

    # vorderer Teil ist ein Wort mit Suffix => siehe Hasenbraten
    # vorderer Teil ist ein Kompositum
    assert_equal([
      [lx('morgenonkelmantel|k'), lx('mantel|s'), lx('morgen|s'), lx('onkel|s'), lx('morgen|w')],
      [6, 5, 6],
      'sss'
    ],
      gra.test_compositum('morgenonkel', '', 'mantel', 1, false)
    )

    # vorderer Teil ist ein TakeItAsIs vor Bindestrich
    assert_equal([
      [lx('arrafat-nachfolger|k'), lx('nachfolger|s'), lx('arrafat|x')],
      [7, 10],
      'xs'
    ],
      gra.test_compositum('arrafat', '-', 'nachfolger', 1, false)
    )

    gra.close
  end

  def test_permute_compositum
    gra = LG.new({'source'=>['sys-dic']}, @lingo)

    # bindestrichversion
    assert_equal([
      [lx('arrafat-nachfolger|k'), lx('nachfolger|s'), lx('arrafat|x')],
      [7, 10],
      'xs'
    ],
      gra.permute_compositum('arrafat-nachfolger', 1, false)
    )

    # bindestrichversion zwei-teilig
    assert_equal([
      [lx('cd-rom-technologie|k'), lx('technologie|s'), lx('cd-rom|x')],
      [6, 11],
      'xs'
    ],
      gra.permute_compositum('cd-rom-technologie', 1, false)
    )

    # bindestrichversion drei-teilig
    assert_equal([
      [lx('albert-ludwigs-universität|k'), lx('universität|s'), lx('albert|e'), lx('ludwig|e')],
      [6, 7, 11],
      'ees'
    ],
      gra.permute_compositum('albert-ludwigs-universität', 1, false)
    )

    # normal mit suggestion
    assert_equal([
      [lx('benutzerforschung|k'), lx('erforschung|s'), lx('benutzen|v')],
      [6, 11],
      'vs'
    ],
      gra.permute_compositum('benutzerforschung', 1, false)
    )

    gra.close
  end

  def test_find_compositum
    gra = LG.new({'source'=>['sys-dic']}, @lingo)
    assert_equal(
      wd('informationswissenschaften|KOM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
      gra.find_compositum('informationswissenschaften')
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
      wd('benutzerforschung|KOM', 'benutzerforschung|k', 'erforschung|s+', 'benutzen|v+'),
      gra.find_compositum('benutzerforschung')
    )
    assert_equal(
      wd('clustersuche|KOM', 'clustersuche|k', 'cluster|s+', 'suche|s+', 'suchen|v+'),
      gra.find_compositum('clustersuche')
    )
    gra.close
  end

  def test_min_word_size
    gra = LG.new({'source'=>['sys-dic']}, @lingo)
    assert_equal( wd('undsund|?'), gra.find_compositum('undsund'))
    gra.close
  end

  def test_max_parts
    gra = LG.new({'source'=>['sys-dic']}, @lingo)
    assert_equal(
      wd('baumsbaumsbaum|KOM', 'baumsbaumsbaum|k', 'baum|s+'),
      gra.find_compositum('baumsbaumsbaum')
    )
    assert_equal(Lingo::Language::Word.new('baumsbaumsbaumsbaumsbaumsbaum', Lingo::Language::WA_UNKNOWN), gra.find_compositum('baumsbaumsbaumsbaumsbaumsbaum'))
    gra.close
  end

end
