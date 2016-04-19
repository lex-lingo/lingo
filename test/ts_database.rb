# encoding: utf-8

require_relative 'test_helper'

class TestDatabase < LingoTestCase

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

    @singleword_inflect = <<-EOT
Wort1
Wort2
juristisch person
natürliche personen
natürlichen quatsches
klug abel
lang essay
große kiefer
warm abendluft
klar abendluft
gut abitur
gut abitur schaffen
ein gut abitur
schmal rund zylinder
der schmal zylinder
wort mist
alt bibliothekskatalog
neu bibliothekskatalög
neu alttitelkatalog
episch dichtung der höfisch zeit
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
      'wort1'                               => 'wort1#s',
      'wort2'                               => 'wort2#s',
      'juristische personen'                => 'juristische personen#s',
      'höher schneller weiter'              => 'höher schneller weiter#s',
      'höher schneller weiter größer'       => 'höher schneller weiter größer#s',
      'ganz großer und blöder quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz großer und blöder mist'         => 'ganz großer und blöder mist#s',
      'ganz großer und blöder schwach sinn' => 'ganz großer und blöder schwach sinn#s'
    })
  end

  def test_singleword_defwc
    compare({
      'txt-format' => 'SingleWord',
      'def-wc'     => '*'
    }, @singleword, {
      'wort1'                               => 'wort1#*',
      'wort2'                               => 'wort2#*',
      'juristische personen'                => 'juristische personen#*',
      'höher schneller weiter'              => 'höher schneller weiter#*',
      'höher schneller weiter größer'       => 'höher schneller weiter größer#*',
      'ganz großer und blöder quatsch'      => 'ganz großer und blöder quatsch#*',
      'ganz großer und blöder mist'         => 'ganz großer und blöder mist#*',
      'ganz großer und blöder schwach sinn' => 'ganz großer und blöder schwach sinn#*'
    })
  end

  def test_singleword_defmulwc
    compare({
      'txt-format' => 'SingleWord',
      'def-mul-wc' => 'm'
    }, @singleword, {
      'wort1'                               => 'wort1#s',
      'wort2'                               => 'wort2#s',
      'juristische personen'                => 'juristische personen#m',
      'höher schneller weiter'              => 'höher schneller weiter#m',
      'höher schneller weiter größer'       => 'höher schneller weiter größer#m',
      'ganz großer und blöder quatsch'      => 'ganz großer und blöder quatsch#m',
      'ganz großer und blöder mist'         => 'ganz großer und blöder mist#m',
      'ganz großer und blöder schwach sinn' => 'ganz großer und blöder schwach sinn#m'
    })
  end

  def test_singleword_uselex
    compare({
      'txt-format' => 'SingleWord',
      'use-lex'    => set_config('lex',
        'name'       => 'de/lingo-dic.txt',
        'txt-format' => 'WordClass',
        'separator'  => '='
      )
    }, @singleword, {
      'wort1'                           => 'wort1#s',
      'wort2'                           => 'wort2#s',
      'ganz groß und blöd mist'         => 'ganz großer und blöder mist#s',
      'juristisch person'               => 'juristische personen#s',
      'hoch schnell weit'               => 'höher schneller weiter#s|*4',
      'ganz groß und blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'hoch schnell weit groß'          => 'höher schneller weiter größer#s',
      'ganz groß und blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und'                   => '*5|*6'
    })
  end

  def test_singleword_inflect
    compare({
      'txt-format' => 'SingleWord',
      'use-lex'    => set_config('lex',
        'name'       => 'de/lingo-dic.txt',
        'txt-format' => 'WordClass',
        'separator'  => '='
      ),
      'inflect'    => true
    }, @singleword_inflect, {
      'wort1'                            => 'wort1#s',
      'wort2'                            => 'wort2#s',
      'juristisch person'                => 'juristische person#s',
      'natürlich person'                 => 'natürliche personen#s',
      'natürlich quatsch'                => 'natürlichen quatsches#s',
      'lang essay'                       => 'langer essay#s',
      'groß kiefer'                      => 'große kiefer#s',
      'klug abel'                        => 'kluger abel#s',
      'warm abendluft'                   => 'warme abendluft#s',
      'klar abendluft'                   => 'klare abendluft#s',
      'gut abitur'                       => 'gutes abitur#s',
      'gut abitur schaff'                => 'gutes abitur schaffen#s',
      'ein gut abitur'                   => 'ein gut abitur#s',
      'schmal rund zylinder'             => 'schmaler runder zylinder#s',
      'der schmal zylinder'              => 'der schmal zylinder#s',
      'wort mist'                        => 'wort mist#s',
      'alt bibliothekskatalog'           => 'alter bibliothekskatalog#s',
      'neu bibliothekskatalög'           => 'neu bibliothekskatalög#s',
      'neu alttitelkatalog'              => 'neuer alttitelkatalog#s',
      'episch dichtung der'              => '*5',
      'episch dichtung der höfisch zeit' => 'epische dichtung der höfisch zeit#s'
    })
  end

  def test_singleword_inflect_s
    compare({
      'txt-format' => 'SingleWord',
      'use-lex'    => set_config('lex',
        'name'       => 'de/lingo-dic.txt',
        'txt-format' => 'WordClass',
        'separator'  => '='
      ),
      'inflect'    => 's'
    }, @singleword_inflect, {
      'wort1'                            => 'wort1#s',
      'wort2'                            => 'wort2#s',
      'juristisch person'                => 'juristische person#s',
      'natürlich person'                 => 'natürliche personen#s',
      'natürlich quatsch'                => 'natürlichen quatsches#s',
      'lang essay'                       => 'langer essay#s',
      'groß kiefer'                      => 'große kiefer#s',
      'klug abel'                        => 'klug abel#s',
      'warm abendluft'                   => 'warme abendluft#s',
      'klar abendluft'                   => 'klare abendluft#s',
      'gut abitur'                       => 'gutes abitur#s',
      'gut abitur schaff'                => 'gutes abitur schaffen#s',
      'ein gut abitur'                   => 'ein gut abitur#s',
      'schmal rund zylinder'             => 'schmaler runder zylinder#s',
      'der schmal zylinder'              => 'der schmal zylinder#s',
      'wort mist'                        => 'wort mist#s',
      'alt bibliothekskatalog'           => 'alter bibliothekskatalog#s',
      'neu bibliothekskatalög'           => 'neu bibliothekskatalög#s',
      'neu alttitelkatalog'              => 'neuer alttitelkatalog#s',
      'episch dichtung der'              => '*5',
      'episch dichtung der höfisch zeit' => 'epische dichtung der höfisch zeit#s'
    })
  end

  def test_singleword_inflect_e
    compare({
      'txt-format' => 'SingleWord',
      'use-lex'    => set_config('lex',
        'name'       => 'de/lingo-dic.txt',
        'txt-format' => 'WordClass',
        'separator'  => '='
      ),
      'inflect'    => 'e'
    }, @singleword_inflect, {
      'wort1'                            => 'wort1#s',
      'wort2'                            => 'wort2#s',
      'juristisch person'                => 'juristisch person#s',
      'natürlich person'                 => 'natürliche personen#s',
      'natürlich quatsch'                => 'natürlichen quatsches#s',
      'lang essay'                       => 'lang essay#s',
      'klug abel'                        => 'kluger abel#s',
      'groß kiefer'                      => 'große kiefer#s',
      'warm abendluft'                   => 'warm abendluft#s',
      'klar abendluft'                   => 'klar abendluft#s',
      'gut abitur'                       => 'gut abitur#s',
      'gut abitur schaff'                => 'gut abitur schaffen#s',
      'ein gut abitur'                   => 'ein gut abitur#s',
      'schmal rund zylinder'             => 'schmal rund zylinder#s',
      'der schmal zylinder'              => 'der schmal zylinder#s',
      'wort mist'                        => 'wort mist#s',
      'alt bibliothekskatalog'           => 'alt bibliothekskatalog#s',
      'neu bibliothekskatalög'           => 'neu bibliothekskatalög#s',
      'neu alttitelkatalog'              => 'neu alttitelkatalog#s',
      'episch dichtung der'              => '*5',
      'episch dichtung der höfisch zeit' => 'episch dichtung der höfisch zeit#s'
    })
  end

  def test_singleword_hyphenate
    compare({
      'txt-format' => 'SingleWord',
      'use-lex'    => set_config('lex',
        'name'       => 'de/lingo-dic.txt',
        'txt-format' => 'WordClass',
        'separator'  => '='
      ),
      'hyphenate'  => true
    }, @singleword, {
      'wort1'                           => 'wort1#s',
      'wort2'                           => 'wort2#s',
      'ganz groß und blöd mist'         => 'ganz großer und blöder mist#s',
      'ganz groß und blöd-mist'         => 'ganz großer und blöder mist#s',
      'ganz groß und-blöd mist'         => 'ganz großer und blöder mist#s',
      'ganz groß und-blöd-mist'         => 'ganz großer und blöder mist#s',
      'ganz groß-und blöd mist'         => 'ganz großer und blöder mist#s',
      'ganz groß-und blöd-mist'         => 'ganz großer und blöder mist#s',
      'ganz groß-und-blöd mist'         => 'ganz großer und blöder mist#s',
      'ganz groß-und-blöd-mist'         => 'ganz großer und blöder mist#s',
      'ganz-groß und blöd mist'         => 'ganz großer und blöder mist#s',
      'ganz-groß und blöd-mist'         => 'ganz großer und blöder mist#s',
      'ganz-groß und-blöd mist'         => 'ganz großer und blöder mist#s',
      'ganz-groß und-blöd-mist'         => 'ganz großer und blöder mist#s',
      'ganz-groß-und blöd mist'         => 'ganz großer und blöder mist#s',
      'ganz-groß-und blöd-mist'         => 'ganz großer und blöder mist#s',
      'ganz-groß-und-blöd mist'         => 'ganz großer und blöder mist#s',
      'juristisch person'               => 'juristische personen#s',
      'hoch schnell weit'               => 'höher schneller weiter#s|*4',
      'hoch schnell-weit'               => 'höher schneller weiter#s',
      'hoch-schnell weit'               => 'höher schneller weiter#s',
      'ganz groß und blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz groß und blöd-quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz groß und-blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz groß und-blöd-quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz groß-und blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz groß-und blöd-quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz groß-und-blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz groß-und-blöd-quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz-groß und blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz-groß und blöd-quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz-groß und-blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz-groß und-blöd-quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz-groß-und blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz-groß-und blöd-quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz-groß-und-blöd quatsch'      => 'ganz großer und blöder quatsch#s',
      'hoch schnell weit groß'          => 'höher schneller weiter größer#s',
      'hoch schnell weit-groß'          => 'höher schneller weiter größer#s',
      'hoch schnell-weit groß'          => 'höher schneller weiter größer#s',
      'hoch schnell-weit-groß'          => 'höher schneller weiter größer#s',
      'hoch-schnell weit groß'          => 'höher schneller weiter größer#s',
      'hoch-schnell weit-groß'          => 'höher schneller weiter größer#s',
      'hoch-schnell-weit groß'          => 'höher schneller weiter größer#s',
      'ganz groß und blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und blöd schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und blöd-schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und blöd-schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und-blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und-blöd schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und-blöd-schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und-blöd-schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß-und blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß-und blöd schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß-und blöd-schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß-und blöd-schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß-und-blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß-und-blöd schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß-und-blöd-schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß-und-blöd-schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß und blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß und blöd schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß und blöd-schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß und blöd-schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß und-blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß und-blöd schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß und-blöd-schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß und-blöd-schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß-und blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß-und blöd schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß-und blöd-schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß-und blöd-schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß-und-blöd schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß-und-blöd schwach-sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz-groß-und-blöd-schwach sinn' => 'ganz großer und blöder schwach sinn#s',
      'ganz groß und'                   => '*4|*5|*6',
      'ganz groß und-blöd'              => '*4|*5',
      'ganz groß und-blöd-schwach'      => '*4',
      'ganz groß-und blöd'              => '*4|*5',
      'ganz groß-und blöd-schwach'      => '*4',
      'ganz groß-und-blöd schwach'      => '*4',
      'ganz-groß und blöd'              => '*4|*5',
      'ganz-groß und blöd-schwach'      => '*4',
      'ganz-groß und-blöd schwach'      => '*4',
      'ganz-groß-und blöd schwach'      => '*4'
    })
  end

  def test_singleword_crypt
    compare({
      'txt-format' => 'SingleWord',
      'crypt'      => true
    }, @singleword) { |db| hash = db.to_h; {
      'wort1'                               => 'wort1#s',
      'wort2'                               => 'wort2#s',
      'juristische personen'                => 'juristische personen#s',
      'höher schneller weiter'              => 'höher schneller weiter#s',
      'höher schneller weiter größer'       => 'höher schneller weiter größer#s',
      'ganz großer und blöder quatsch'      => 'ganz großer und blöder quatsch#s',
      'ganz großer und blöder mist'         => 'ganz großer und blöder mist#s',
      'ganz großer und blöder schwach sinn' => 'ganz großer und blöder schwach sinn#s'
    }.each { |key, val|
      assert_nil(hash[key])
      assert_equal([val], db[key])

      assert_nil(db[digest = Lingo::Database::Crypter.digest(key)])
      assert_not_equal(key, digest)

      assert_instance_of(String, encrypted = hash[digest])
      assert_not_equal(val, encrypted)
    } }
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
      'wort1'           => 'projektion1#s|projektion4#s|projektion5#s',
      'wort2'           => 'projektion2#s',
      'wort3'           => 'projektion3#s',
      'mehr wort satz'  => 'pro jeck zion 1#s|pro jeck zion 2#s',
      'albert einstein' => 'einstein, albert#s'
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
      Wort4.illegal
      Wort4=still illegal
      Wort4=still illegal#s!
      Wort4=now we're talking#s+
    }, {
      'wort1' => 'projektion1#h#|projektion4#e#',
      'wort2' => 'projektion2#i#',
      'wort3' => 'projektion3#e#',
      'wort4' => "now we're talking#s+#"
    })
  end

  def test_wordclass_gender
    compare({
      'txt-format' => 'WordClass'
    }, %q{
      substantiv,substantiv #a substantiv #s.n
      mehr,mehr #w mehr #s.n mehren #v
      wort,wort #s.n
      gruppe,gruppe #s.f
      modul,modul #s.m|n
      nocken,nock #s.f|m|n nocke #s.f nocken #s.m
      albern,albern #a|v
      fortuna,fortuna #e|s.f
    }, {
      'substantiv' => 'substantiv#a#|substantiv#s#n',
      'mehr'       => 'mehr#w#|mehr#s#n|mehren#v#',
      'wort'       => 'wort#s#n',
      'gruppe'     => 'gruppe#s#f',
      'modul'      => 'modul#s#m|modul#s#n',
      'nocken'     => 'nock#s#f|nock#s#m|nock#s#n|nocke#s#f|nocken#s#m',
      'albern'     => 'albern#a#|albern#v#',
      'fortuna'    => 'fortuna#e#f|fortuna#s#f'
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
      'hasen'        => 'hasen|nasen|vasen|rasen',
      'nasen'        => 'hasen|nasen|vasen|rasen',
      'vasen'        => 'hasen|nasen|vasen|rasen',
      'rasen'        => 'hasen|nasen|vasen|rasen|gras|grüne fläche|rennen|wettrennen',
      'gold'         => 'gold|edelmetall|mehrwert',
      'edelmetall'   => 'gold|edelmetall|mehrwert',
      'mehrwert'     => 'gold|edelmetall|mehrwert',
      'gras'         => 'rasen|gras|grüne fläche',
      'grüne fläche' => 'rasen|gras|grüne fläche',
      'rennen'       => 'rasen|rennen|wettrennen',
      'wettrennen'   => 'rasen|rennen|wettrennen'
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
    File.open(TEST_FILE, 'w', encoding: Lingo::ENCODING) { |f| f.write(input) }

    id, err = set_config('tst', config.merge('name' => TEST_FILE)), nil

    Lingo::Database.open(id, @lingo) { |db| begin
      block_given? ? yield(db) : assert_equal(output, db.to_h
        .tap { |h| h.delete(Lingo::Database::SYS_KEY) }); rescue => err; end }

    raise err if err
  ensure
    cleanup_store
  end

  def set_config(id, config)
    "_test_#{id}_".tap { |i| @lingo.config["language/dictionary/databases/#{i}"] = config }
  end

end
