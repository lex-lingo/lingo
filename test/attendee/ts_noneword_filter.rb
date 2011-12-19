# encoding: utf-8

require_relative 'globals'

################################################################################
#
#    Attendee Noneword_filter
#
class TestAttendeeNoneword_filter < LingoTestCase

  def test_basic
    @input = [wd('Eins|IDF'), wd('Zwei|?'), wd('Drei|IDF'), wd('Vier|?'), ai('EOF|')]
    @expect = ['vier', 'zwei', ai('EOF|')]
    meet({})
  end

end
#
################################################################################
