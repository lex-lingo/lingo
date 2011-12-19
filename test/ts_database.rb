# encoding: utf-8

require 'test/unit'
require 'lingo'

class Txt2DbmConverter
  alias_method :original_initialize, :initialize
  def initialize(id, lingo, verbose = false)
    original_initialize(id, lingo, verbose)
  end
end

class TestDatabase < Test::Unit::TestCase

  TEST_FILE = 'test/de/test.txt'
  TEST_GLOB = "#{File.dirname(TEST_FILE)}/{,store/}#{File.basename(TEST_FILE, '.txt')}*"

  def setup
    @lingo = Lingo.new

    @singleword = <<-EOT
Wort1
Wort2
Wort2
juristische Personen
höher schneller weiter
höher schneller weiter größer
ganz großer und blöder quatsch
ganz großer und blöder mist
ganz großer und blöder schwach sinn
    EOT

    @keyvalue = <<-EOT
Wort1*Projektion1
Wort2*Projektion2
Wort3*Projektion3
Wort4*
Wort1*Projektion4
Wort1 * Projektion5
Mehr Wort Satz*Pro Jeck Zion 1
Mehr Wort Satz*Pro Jeck Zion 2
Albert Einstein*Einstein, Albert
    EOT

    @wordclass = <<-EOT
Wort1=Projektion1#h
Wort2=Projektion2#i
Wort3=Projektion3#e
Wort1=Projektion4 #e
Wort1=#s
Wort2=
    EOT
  end

  def test_singleword
    compare({
      'txt-format' => 'SingleWord'
    }, @singleword, {
      'wort1'                               => '#s',
      'wort2'                               => '#s',
      'juristische personen'                => '#s',
      'höher schneller weiter'              => '#s',
      'höher schneller weiter größer'       => '#s',
      'ganz großer und blöder quatsch'      => '#s',
      'ganz großer und blöder mist'         => '#s',
      'ganz großer und blöder schwach sinn' => '#s'
    })
  end

  def test_singleword_defwc
    compare({
      'txt-format' => 'SingleWord',
      'def-wc'     => '*'
    }, @singleword, {
      'wort1'                               => '#*',
      'wort2'                               => '#*',
      'juristische personen'                => '#*',
      'höher schneller weiter'              => '#*',
      'höher schneller weiter größer'       => '#*',
      'ganz großer und blöder quatsch'      => '#*',
      'ganz großer und blöder mist'         => '#*',
      'ganz großer und blöder schwach sinn' => '#*'
    })
  end

  def test_singleword_defmulwc
    compare({
      'txt-format' => 'SingleWord',
      'def-mul-wc' => 'm'
    }, @singleword, {
      'wort1'                               => '#s',
      'wort2'                               => '#s',
      'juristische personen'                => '#m',
      'höher schneller weiter'              => '#m',
      'höher schneller weiter größer'       => '#m',
      'ganz großer und blöder quatsch'      => '#m',
      'ganz großer und blöder mist'         => '#m',
      'ganz großer und blöder schwach sinn' => '#m'
    })
  end

  def test_singleword_uselex
    compare({
      'txt-format' => 'SingleWord',
      'use-lex'    => set_config('lex',
        'name'       => 'de/lingo-dic.txt',
        'txt-format' => 'WordClass'
      )
    }, @singleword, {
      'wort1'                           => '#s',
      'wort2'                           => '#s',
      'ganz groß und blöd mist'         => 'ganz großer und blöder mist#s',
      'juristisch person'               => 'juristische personen#s',
      'hoch schnell weit'               => '*4|höher schneller weiter#s',
      'ganz groß und blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'hoch schnell weit groß'          => 'höher schneller weiter größer#s',
      'ganz groß und blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und'                   => '*5|*6'
    })
  end

  def test_singleword_crypt
    config = {
      'txt-format' => 'SingleWord',
      'crypt'      => true
    }

    compare(config, @singleword, {
      'd8ac4360a5f707d518212e27dcba9dd42d980f96' => '5116',
      '81463f9c7e0ad40e329e83d3358232851d50ed9a' => '4d16',
      '8da4a0c30c912543be2d88da64c0192e577efa9d' => '1107',
      '2c24b4707e77c74abfb12748317693dc1e43c215' => '5700',
      '810ff7a76f39febcb1cf67993d4fb29819ce40a6' => '5116',
      'a28b4ca84ac08aeef4e420445f94f632ad010a30' => '1207',
      '1496f4febbc647f3ac74b0af11dadbd6322f6732' => '4d1d',
      'b7501a62cb083be6730a7a179a4ab346d23efe53' => '4b10'
    })

    compare(config, @singleword) { |dbm| {
      'wort1'                               => '#s',
      'wort2'                               => '#s',
      'juristische personen'                => '#s',
      'höher schneller weiter'              => '#s',
      'höher schneller weiter größer'       => '#s',
      'ganz großer und blöder quatsch'      => '#s',
      'ganz großer und blöder mist'         => '#s',
      'ganz großer und blöder schwach sinn' => '#s'
    }.each { |key, val| assert_equal([val], dbm[key]) } }
  end

  def test_keyvalue
    compare({
      'txt-format' => 'KeyValue'
    }, @keyvalue, {
      'wort1'           => 'projektion1#?|projektion4#?|projektion5#?',
      'wort2'           => 'projektion2#?',
      'wort3'           => 'projektion3#?',
      'mehr wort satz'  => 'pro jeck zion 1#?|pro jeck zion 2#?',
      'albert einstein' => 'einstein, albert#?'
    })
  end

  def test_keyvalue_separator
    compare({
      'txt-format' => 'KeyValue',
      'separator'  => '*'
    }, @keyvalue, {
      'wort1'           => 'projektion1#?|projektion4#?|projektion5#?',
      'wort2'           => 'projektion2#?',
      'wort3'           => 'projektion3#?',
      'mehr wort satz'  => 'pro jeck zion 1#?|pro jeck zion 2#?',
      'albert einstein' => 'einstein, albert#?'
    })
  end

  def test_keyvalue_defwc
    compare({
      'txt-format' => 'KeyValue',
      'separator'  => '*',
      'def-wc'     => 's'
    }, @keyvalue, {
      'wort1'=>'projektion1#s|projektion4#s|projektion5#s',
      'wort2'=>'projektion2#s',
      'wort3'=>'projektion3#s',
      'mehr wort satz'=>'pro jeck zion 1#s|pro jeck zion 2#s',
      'albert einstein'=>'einstein, albert#s'
    })
  end

  def test_wordclass
    compare({
      'txt-format' => 'WordClass',
      'separator'  => '='
    }, %q{
      Wort1=Projektion1#h
      Wort2=Projektion2#i
      Wort3=Projektion3#e
      Wort1=Projektion4 #e
      Wort1=#s
      Wort2=
    }, {
      'wort1' => 'projektion1#h|projektion4#e',
      'wort2' => 'projektion2#i',
      'wort3' => 'projektion3#e'
    })
  end

  def test_multivalue
    compare({
      'txt-format' => 'MultiValue',
      'separator'  => ';'
    }, %q{
      Hasen;Nasen;Vasen;Rasen
      Gold;Edelmetall;Mehrwert
      Rasen;Gras;Grüne Fläche
      Rasen;Rennen;Wettrennen
    }, {
      '^0'           => 'hasen|nasen|rasen|vasen',
      '^1'           => 'edelmetall|gold|mehrwert',
      '^2'           => 'gras|grüne fläche|rasen',
      '^3'           => 'rasen|rennen|wettrennen',
      'hasen'        => '^0',
      'nasen'        => '^0',
      'rasen'        => '^0|^2|^3',
      'vasen'        => '^0',
      'edelmetall'   => '^1',
      'gold'         => '^1',
      'mehrwert'     => '^1',
      'gras'         => '^2',
      'grüne fläche' => '^2',
      'wettrennen'   => '^3',
      'rennen'       => '^3'
    })
  end

  def test_multikey
    compare({
      'txt-format' => 'MultiKey'
    }, %q{
      Hasen;Nasen;Vasen;Rasen
      Gold;Edelmetall;Mehrwert
    }, {
      'nasen'      => 'hasen',
      'vasen'      => 'hasen',
      'rasen'      => 'hasen',
      'edelmetall' => 'gold',
      'mehrwert'   => 'gold',
    })
  end

  def compare(config, input, output = nil)
    FileUtils.mkdir_p(File.dirname(TEST_FILE))
    File.open(TEST_FILE, 'w', :encoding => ENC) { |f| f.puts input }

    DbmFile.open(set_config('tst', config.merge('name' => TEST_FILE)), @lingo) { |dbm|
      if block_given?
        yield dbm
      else
        store = dbm.to_h
        store.delete(SYS_KEY)

        assert_equal(output, store)
      end
    }
  ensure
    Dir[TEST_GLOB].each { |f| File.unlink(f) }
  end

  def set_config(id, config)
    id = "_test_#{id}_"
    @lingo.config["language/dictionary/databases/#{id}"] = config
    id
  end

end
