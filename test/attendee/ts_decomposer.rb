# encoding: utf-8

require_relative '../test_helper'

################################################################################
#
# Attendee Decomposer
#
class TestAttendeeDecomposer < AttendeeTestCase

  def test_basic
    @input = [
      wd('Kleinseite|?'),
      wd('Arrafat-Nachfolger|?'),
      wd('Afganistan-Reisen|?'),
      wd('Kompositumzerlegung|?'),
      wd('Kompositumzerlegung|?')
    ]
    @expect = [
      wd('Kleinseite|KOM', 'kleinseite|k', 'klein|a+', 'seite|s+'),
      wd('Arrafat-Nachfolger|KOM', 'arrafat-nachfolger|k', 'nachfolger|s+', 'arrafat|x+'),
      wd('Afganistan-Reisen|KOM', 'afganistan-reise|k', 'reise|s+', 'reisen|v+', 'afganistan|x+'),
      wd('Kompositumzerlegung|KOM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+'),
      wd('Kompositumzerlegung|KOM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+')
    ]
    meet({'source'=>'sys-dic'})
  end

end
#
################################################################################
