# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeVariator < AttendeeTestCase

  def test_basic
    meet({ 'source' => 'sys-dic' }, [
      wd('fchwarz|?'), wd('fchilling|?'), wd('iehwarzfchilling|?'), wd('fchiiiirg|?')
    ], [
      wd('*schwarz|IDF', 'schwarz|s', 'schwarz|a'),
      wd('*schilling|IDF', 'schilling|s'),
      wd('*schwarzschilling|KOM', 'schwarzschilling|k', 'schwarz|s+', 'schwarz|a+', 'schilling|s+'),
      wd('fchiiiirg|?')
    ])
  end

end
