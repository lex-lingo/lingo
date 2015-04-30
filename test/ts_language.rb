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

  def test_cache
    lh('sys-dic') { |ds|
      assert_equal([lx('regen|s|m'), lx('regen|s|n'), lx('regen|v'), lx('rege|a')], ds['regen'])
      assert_equal([lx('regen|s|m'), lx('regen|s|n'), lx('regen|v'), lx('rege|a')], ds['regen'])
      assert_equal([lx('regen|s|m'), lx('regen|s|n'), lx('regen|v'), lx('rege|a')], ds['regen'])
    }
  end

  def test_auto_create
    txt_file = @database_config[id = 'tst-sgw']['name']

    lh(id) { |ds| assert_equal([lx('substantiv|s')], ds['substantiv']) }

    File.delete(*Dir["#{Lingo.find(:store, txt_file)}.*"])
    lh(id) { |ds| assert_equal([lx('substantiv|s')], ds['substantiv']) }

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
      assert_equal([4], ds['abelscher ring ohne'])
      assert_equal([lx('alleinreisende frau|m')], ds['alleinreisend frau'])
      assert_equal([lx('abschaltbarer leistungshalbleiter|m')], ds['abschaltbarer leistungshalbleiter'])
      assert_equal(nil, ds['abschaltbar leistungshalbleiter'])
    }
  end

  def test_wordclass
    lh('sys-dic') { |ds|
      assert_equal([lx('a-dur|s|m'), lx('a-dur|s|n')], ds['a-dur'])
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
      assert_equal([], dic.select('hasennasen'))
      assert_equal([lx('knaller|s')], dic.select('knaller'))
      assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
      assert_equal([lx('a-dur|s|m'), lx('a-dur|s|n')], dic.select('a-dur'))
    }
  end

  def test_select_two_sources_mode_first_flipped
    ld('source' => %w[tst-dic sys-dic], 'mode' => 'first') { |dic|
      assert_equal([], dic.select('hasennasen'))
      assert_equal([lx('knaller|s')], dic.select('knaller'))
      assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
      assert_equal([lx('b-dur|s')], dic.select('a-dur'))
    }
  end

  def test_select_two_sources_mode_all
    ld('source' => %w[sys-dic tst-dic], 'mode' => 'all') { |dic|
      assert_equal([], dic.select('hasennasen'))
      assert_equal([lx('knaller|s')], dic.select('knaller'))
      assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
      assert_equal([lx('a-dur|s|m'), lx('a-dur|s|n'), lx('b-dur|s')], dic.select('a-dur'))
      assert_equal([lx('aas|s|n'), lx('aas|s')], dic.select('aas'))
    }
  end

  def test_select_two_sources_mode_default
    ld('source' => %w[sys-dic tst-dic]) { |dic|
      assert_equal([], dic.select('hasennasen'))
      assert_equal([lx('knaller|s')], dic.select('knaller'))
      assert_equal([lx('super indexierungssystem|m')], dic.select('lex-lingo'))
      assert_equal([lx('wirkungsort|s'), lx('wirkung|s+'), lx('ort|s+')], dic.select('wirkungsort'))
      assert_equal([lx('zettelkatalog|k'), lx('zettel|s+'), lx('katalog|s+')], dic.select('zettelkatalog'))
      assert_equal([lx('a-dur|s|m'), lx('a-dur|s|n'), lx('b-dur|s')], dic.select('a-dur'))
      assert_equal([lx('aas|s|n'), lx('aas|s')], dic.select('aas'))
    }
  end

  def test_suffix_lexicals
    ld('source' => %w[sys-dic]) { |dic|
      assert_equal([lx('mau|s'), lx('mauer|s')], ax(dic, 'mauern'))
      assert_equal([lx('hasen|s'), lx('hasen|v'), lx('hasen|e')], ax(dic, 'hasens'))
      assert_equal([lx('schönst|s'), lx('schön|a'), lx('schönst|a')], ax(dic, 'schönster'))
      assert_equal([lx('segnen|v'), lx('segneen|v')], ax(dic, 'segnet'))
    }
  end

  def test_infix_lexicals
    ld('source' => %w[sys-dic]) { |dic|
      assert_equal([lx('information|f')], ax(dic, 'informations', :infix))
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
      assert_equal([lx('information|f')], ax(dic, 'informations', :infix))
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

  def ax(dic, *args)
    [].tap { |x| dic.each_affix(*args) { |*a| x << Lingo::Language::Lexical.new(*a) } }
  end

end

class TestGrammar < LingoTestCase

  def setup
    @lingo = Lingo.new
  end

  def test_cache
    lg { |gra|
      assert_equal(
        wd('informationswissenschaften|COM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
        gra.find_compound('informationswissenschaften')
      )
      assert_equal(
        wd('informationswissenschaften|COM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
        gra.find_compound('informationswissenschaften')
      )
      assert_equal(
        wd('informationswissenschaften|COM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
        gra.find_compound('informationswissenschaften')
      )
    }
  end

  def test_find_compound
    lg { |gra|
      assert_equal(
        wd('informationswissenschaften|COM', 'informationswissenschaft|k', 'information|s+', 'wissenschaft|s+'),
        gra.find_compound('informationswissenschaften')
      )

      assert_equal(
        wd('cd-rom-technologie|COM', 'cd-rom-technologie|k', 'cd-rom|s+|f', 'cd-rom|s+|m', 'technologie|s+|f'),
        gra.find_compound('cd-rom-technologie')
      )

      assert_equal(
        wd('albert-ludwigs-universität|COM', 'albert-ludwigs-universität|k', 'albert|e+', 'ludwig|e+', 'universität|s+'),
        gra.find_compound('albert-ludwigs-universität')
      )

      assert_equal(
        wd('client-server-system|COM', 'client-server-system|k', 'client|s+', 'server|s+', 'system|s+'),
        gra.find_compound('client-server-system')
      )

      assert_equal(
        wd('benutzerforschung|COM', 'benutzerforschung|k', 'benutzer|s+', 'forschung|s+'),
        gra.find_compound('benutzerforschung')
      )

      assert_equal(
        wd('clustersuche|COM', 'clustersuche|k', 'cluster|s+', 'suche|s+', 'suchen|v+'),
        gra.find_compound('clustersuche')
      )

      assert_equal(
        wd('titelkatalogstitel|COM', 'titelkatalogstitel|k', 'titel|s+', 'katalog|s+', 'titel|s+'),
        gra.find_compound('titelkatalogstitel')
      )

      assert_equal(
        wd('titelkatalogstiteltitel|COM', 'titelkatalogstiteltitel|k', 'titel|s+', 'katalog|s+', 'titel|s+', 'titel|s+'),
        gra.find_compound('titelkatalogstiteltitel')
      )

      assert_equal(
        wd('titelbestandsbestände|COM', 'titelbestandsbestand|k', 'titel|s+', 'bestand|s+', 'bestand|s+', 'bestehen|v+'),
        gra.find_compound('titelbestandsbestände')
      )

      assert_equal(
        wd('hasenbraten|COM', 'hasenbraten|k', 'hase|s+', 'braten|v+'),
        gra.find_compound('hasenbraten')
      )

      assert_equal(
        wd('nasenlaufen|COM', 'nasenlaufen|k', 'nase|s+', 'laufen|v+'),
        gra.find_compound('nasenlaufen')
      )

      assert_equal(
        wd('nasenlaufens|COM', 'nasenlaufen|k', 'nase|s+', 'laufen|v+'),
        gra.find_compound('nasenlaufens')
      )

      assert_equal(
        wd('arrafat-nachfolgebedarf|COM', 'arrafat-nachfolgebedarf|k', 'arrafat|x+', 'nachfolge|s+', 'bedarf|s+'),
        gra.find_compound('arrafat-nachfolgebedarf')
      )

      assert_equal(
        wd('nachfolge-arrafat|COM', 'nachfolge-arrafat|k', 'nachfolge|s+', 'arrafat|x+'),
        gra.find_compound('nachfolge-arrafat')
      )

      assert_equal(
        wd('morgenonkelmantel|COM', 'morgenonkelmantel|k', 'morgen|w+', 'morgen|s+', 'onkel|s+', 'mantel|s+'),
        gra.find_compound('morgenonkelmantel')
      )

      assert_equal(
        wd('arrafat-nachfolger|COM', 'arrafat-nachfolger|k', 'arrafat|x+', 'nachfolger|s+'),
        gra.find_compound('arrafat-nachfolger')
      )

      assert_equal(
        wd('cd-rom-technologie|COM', 'cd-rom-technologie|k', 'cd-rom|s+|f', 'cd-rom|s+|m', 'technologie|s+|f'),
        gra.find_compound('cd-rom-technologie')
      )

      assert_equal(
        wd('albert-ludwigs-universität|COM', 'albert-ludwigs-universität|k', 'albert|e+', 'ludwig|e+', 'universität|s+'),
        gra.find_compound('albert-ludwigs-universität')
      )

      assert_equal(
        wd('benutzerforschung|COM', 'benutzerforschung|k', 'benutzer|s+', 'forschung|s+'),
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
      assert_equal(wd('baumsbaumsbaum|COM', 'baumsbaumsbaum|k', 'baum|s+', 'baum|s+', 'baum|s+'), gra.find_compound('baumsbaumsbaum'))
      assert_equal(wd('baumsbaumsbaumsbaumsbaumsbaum|?'), gra.find_compound('baumsbaumsbaumsbaumsbaumsbaum'))
    }
  end

  def lg(&block)
    Lingo::Language::Grammar.open({ 'source' => %w[sys-dic] }, @lingo, &block)
  end

end
