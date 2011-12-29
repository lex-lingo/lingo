# encoding: utf-8

require_relative '../test_helper'

################################################################################
#
# Attendee Noneword_filter
#
class TestAttendeeNoneword_filter < AttendeeTestCase

  def test_basic
    @input = [wd('Eins|IDF'), wd('Zwei|?'), wd('Drei|IDF'), wd('Vier|?'), ai('EOF|')]
    @expect = ['vier', 'zwei', ai('EOF|')]
    meet({})
  end

end
#
################################################################################
