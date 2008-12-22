require 'test/attendee/globals'

################################################################################
#
#    Attendee Variator
#
class TestAttendeeVariator < Test::Unit::TestCase

  def test_basic
    @input = [wd('fchwarz|?'), wd('fchilling|?'), wd('iehwarzfchilling|?'), wd('fchiiiirg|?')]
    @expect = [
      wd('*schwarz|IDF', 'schwarz|a'),
      wd('*schilling|IDF', 'schilling|s'),
      wd('*schwarzschilling|KOM', 'schwarzschilling|k', 'schwarz|a+', 'schilling|s+'),
      wd('fchiiiirg|?')
    ]
    meet({'source'=>'sys-dic'})
  end

end
#
################################################################################
