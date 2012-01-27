# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeVariator < AttendeeTestCase

  def test_basic
    @input = [wd('fchwarz|?'), wd('fchilling|?'), wd('iehwarzfchilling|?'), wd('fchiiiirg|?')]
    @expect = [
      wd('*schwarz|IDF', 'schwarz|s', 'schwarz|a'),
      wd('*schilling|IDF', 'schilling|s'),
      wd('*schwarzschilling|KOM', 'schwarzschilling|k', 'schwarz|a+', 'schilling|s+', 'schwarz|s+'),
      wd('fchiiiirg|?')
    ]
    meet({'source'=>'sys-dic'})
  end

end
