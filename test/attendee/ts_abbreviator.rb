# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeAbbreviator < AttendeeTestCase

  def test_basic
    meet({ 'source' => 'sys-abk' }, [
      tk('z.b|ABRV'), tk('.|PUNC'),
      tk('im|WORD'),
      tk('14.|NUMS'),
      tk('bzw|WORD'), tk('.|PUNC'),
      tk('15.|NUMS'),
      tk('Jh|WORD'), tk('.|PUNC'),
      ai('EOL|')
    ], [
      wd('z.b.|IDF', 'zum beispiel|w'),
      tk('im|WORD'),
      tk('14.|NUMS'),
      wd('bzw.|IDF', 'beziehungsweise|w'),
      tk('15.|NUMS'),
      wd('Jh.|IDF', 'jahrhundert|s'),
      ai('EOL|')
    ])
  end

  def test_sentence
    meet({ 'source' => 'sys-abk' }, [
      tk('Dieser|WORD'),
      tk('Satz|WORD'),
      tk('hat|WORD'),
      tk('keinen|WORD'),
      tk('Punkt|WORD'),
      tk('am|WORD'),
      tk('Ende|WORD'),
      ai('EOF|')
    ], [
      tk('Dieser|WORD'),
      tk('Satz|WORD'),
      tk('hat|WORD'),
      tk('keinen|WORD'),
      tk('Punkt|WORD'),
      tk('am|WORD'),
      tk('Ende|WORD'),
      ai('EOF|')
    ])
  end

end
