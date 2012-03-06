# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeNonewordFilter < AttendeeTestCase

  def test_basic
    meet({}, [
      wd('Eins|IDF'), wd('Zwei|?'), wd('Drei|IDF'), wd('Vier|?'), ai('EOF|')
    ], [
      'vier', 'zwei', ai('EOF|')
    ])
  end

end
