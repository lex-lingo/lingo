# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeSequencer < AttendeeTestCase

  def test_basic
    meet({ 'stopper' => 'PUNC,OTHR', 'source' => 'sys-mul' }, [
      # AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|KOM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      ai('EOF|')
    ], [
      # AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      wd('sonne, hell|SEQ', 'sonne, hell|q'),
      # AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|KOM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      wd('sonnenuntergang, schön|SEQ', 'sonnenuntergang, schön|q'),
      ai('EOF|')
    ])
  end

end
