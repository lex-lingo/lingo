require 'test/attendee/globals'

################################################################################
#
#    Attendee Wordsearcher
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