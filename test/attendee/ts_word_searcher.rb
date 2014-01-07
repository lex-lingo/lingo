# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeWordSearcher < AttendeeTestCase

  def test_basic
    meet({ 'source' => 'sys-dic,sys-syn,sys-mul' }, [
      tk('Dies|WORD'), tk('ist|WORD'), tk('ein|WORD'), tk('Test|WORD'), tk('.|PUNC'), ai('EOL|')
    ], [
      wd('Dies|IDF', 'dies|w'),
      wd('ist|IDF', 'sein|v'),
      wd('ein|IDF', 'ein|w', 'einen|v'),
      wd('Test|IDF', 'test|s', 'testen|v'),
      tk('.|PUNC'),
      ai('EOL|')
    ])
  end

  def test_mode
    meet({ 'source' => 'sys-syn,sys-dic', 'mode' => 'first' }, [
      tk('Dies|WORD'), tk('ist|WORD'), tk('ein|WORD'), tk('Test|WORD'), tk('.|PUNC'), ai('EOL|')
    ], [
      wd('Dies|IDF', 'dies|w'),
      wd('ist|IDF', 'sein|v'),
      wd('ein|IDF', 'ein|w', 'einen|v'),
      wd('Test|IDF', 'test|s', 'testen|v'),
      tk('.|PUNC'),
      ai('EOL|')
    ])
  end

  def test_two_sources_mode_first
    meet({ 'source' => 'sys-dic,tst-dic', 'mode' => 'first' }, [
      tk('Hasennasen|WORD'),
      tk('Knaller|WORD'),
      tk('Lex-Lingo|WORD'),
      tk('A-Dur|WORD'),
      ai('EOL|')
    ], [
      wd('Hasennasen|?'),
      wd('Knaller|IDF', 'knaller|s'),
      wd('Lex-Lingo|IDF', 'super indexierungssystem|m'),
      wd('A-Dur|IDF', 'a-dur|s'),
      ai('EOL|')
    ])
  end

  def test_two_sources_mode_first_flipped
    meet({ 'source' => 'tst-dic,sys-dic', 'mode' => 'first' }, [
      tk('Hasennasen|WORD'),
      tk('Knaller|WORD'),
      tk('Lex-Lingo|WORD'),
      tk('A-Dur|WORD'),
      ai('EOL|')
    ], [
      wd('Hasennasen|?'),
      wd('Knaller|IDF', 'knaller|s'),
      wd('Lex-Lingo|IDF', 'super indexierungssystem|m'),
      wd('A-Dur|IDF', 'b-dur|s'),
      ai('EOL|')
    ])
  end

  def test_select_two_sources_mode_all
    meet({ 'source' => 'sys-dic,tst-dic', 'mode' => 'all' }, [
      tk('Hasennasen|WORD'),
      tk('Knaller|WORD'),
      tk('Lex-Lingo|WORD'),
      tk('A-Dur|WORD'),
      ai('EOL|')
    ], [
      wd('Hasennasen|?'),
      wd('Knaller|IDF', 'knaller|s'),
      wd('Lex-Lingo|IDF', 'super indexierungssystem|m'),
      wd('A-Dur|IDF', 'a-dur|s', 'b-dur|s'),
      ai('EOL|')
    ])
  end

  def test_select_two_sources_mode_default
    meet({ 'source' => 'sys-dic,tst-dic' }, [
      tk('Hasennasen|WORD'),
      tk('Knaller|WORD'),
      tk('Lex-Lingo|WORD'),
      tk('A-Dur|WORD'),
      tk('Wirkungsort|WORD'),
      tk('Zettelkatalog|WORD'),
      ai('EOL|')
    ], [
      wd('Hasennasen|?'),
      wd('Knaller|IDF', 'knaller|s'),
      wd('Lex-Lingo|IDF', 'super indexierungssystem|m'),
      wd('A-Dur|IDF', 'a-dur|s', 'b-dur|s'),
      wd('Wirkungsort|IDF', 'wirkungsort|s', 'wirkung|s+', 'ort|s+'),
      wd('Zettelkatalog|KOM', 'zettelkatalog|k', 'zettel|s+', 'katalog|s+'),
      ai('EOL|')
    ])
  end

end
