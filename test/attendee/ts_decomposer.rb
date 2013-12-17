# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeDecomposer < AttendeeTestCase

  def test_basic
    meet({ 'source' => 'sys-dic' }, [
      wd('Kleinseite|?'),
      wd('Arrafat-Nachfolger|?'),
      wd('Afganistan-Reisen|?'),
      wd('Kompositumzerlegung|?'),
      wd('Kompositumzerlegung|?')
    ], [
      wd('Kleinseite|KOM', 'kleinseite|k', 'klein|a+', 'seite|s+'),
      wd('Arrafat-Nachfolger|KOM', 'arrafat-nachfolger|k', 'arrafat|x+', 'nachfolger|s+'),
      wd('Afganistan-Reisen|KOM', 'afganistan-reise|k', 'afganistan|x+', 'reise|s+', 'reisen|v+'),
      wd('Kompositumzerlegung|KOM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+'),
      wd('Kompositumzerlegung|KOM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+')
    ])
  end

end
