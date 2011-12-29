# encoding: utf-8

require_relative '../test_helper'

################################################################################
#
# Attendee Sequencer
#
class TestAttendeeSequencer < AttendeeTestCase

  def test_basic
    @input = [
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
    ]
    @expect = [
      # AS
      wd('Die|IDF', 'die|w'),
      wd('sonne, hell|SEQ', 'sonne, hell|q'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # AK
      wd('Der|IDF', 'der|w'),
      wd('sonnenuntergang, schön|SEQ', 'sonnenuntergang, schön|q'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|KOM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      ai('EOF|')
    ]
    meet({'stopper'=>'PUNC,OTHR', 'source'=>'sys-mul'})
  end

end
#
################################################################################
