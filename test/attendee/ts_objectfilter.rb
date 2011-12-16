# encoding: utf-8

require_relative 'globals'

################################################################################
#
#    Attendee Objectfilter
#
class TestAttendeeObjectfilter < Test::Unit::TestCase

  def test_basic
    @input = [wd('Eins|IDF'), wd('zwei|?'), wd('Drei|IDF'), wd('vier|?'), ai('EOF|')]
    @expect = [wd('Eins|IDF'), wd('Drei|IDF'), ai('EOF|')]
    meet({'objects'=>'obj.form =~ /^[A-Z]/'})
  end

end
#
################################################################################
