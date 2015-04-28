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
      wd('Afganistan-Reisen|KOM', 'afganistan-reisen|k', 'afganistan|x+', 'reisen|v+', 'reise|s+'),
      wd('Kompositumzerlegung|KOM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+'),
      wd('Kompositumzerlegung|KOM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+')
    ])
  end

  def test_nums
    meet({ 'source' => 'sys-dic' }, [
      wd('123-Reisen|?'),
      wd('abc123-Reisen|?'),
      wd('Reisen-24|?'),
      wd('Reisen-123|?'),
      wd('Reisen-24-Seite|?'),
      wd('Reisen-123-Seite|?')
    ], [
      wd('123-Reisen|KOM', '123-reisen|k', '123|x+', 'reisen|v+', 'reise|s+'),
      wd('abc123-Reisen|KOM', 'abc123-reisen|k', 'abc123|x+', 'reisen|v+', 'reise|s+'),
      wd('Reisen-24|?'),
      wd('Reisen-123|KOM', 'reisen-123|k', 'reisen|v+', 'reise|s+', '123|x+'),
      wd('Reisen-24-Seite|KOM', 'reisen-24-seite|k', 'reisen-24|x+', 'seite|s+'),
      wd('Reisen-123-Seite|KOM', 'reisen-123-seite|k', 'reisen|v+', 'reise|s+', '123|x+', 'seite|s+')
    ])
  end

end
