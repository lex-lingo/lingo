# encoding: utf-8

require './test/attendee/globals'

################################################################################
#
#    Attendee Noneword_filter
#
class TestAttendeeNoneword_filter < Test::Unit::TestCase

  def test_basic
    @input = [wd('Eins|IDF'), wd('Zwei|?'), wd('Drei|IDF'), wd('Vier|?'), ai('EOF|')]
    @expect = ['vier', 'zwei', ai('EOF|')]
    meet({})
  end

end
#
################################################################################
