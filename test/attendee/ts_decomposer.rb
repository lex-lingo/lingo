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
      wd('Kleinseite|COM', 'kleinseite|k', 'klein|a+', 'seite|s+'),
      wd('Arrafat-Nachfolger|COM', 'arrafat-nachfolger|k', 'arrafat|x+', 'nachfolger|s+'),
      wd('Afganistan-Reisen|COM', 'afganistan-reisen|k', 'afganistan|x+', 'reisen|v+', 'reise|s+'),
      wd('Kompositumzerlegung|COM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+'),
      wd('Kompositumzerlegung|COM', 'kompositumzerlegung|k', 'kompositum|s+', 'zerlegung|s+')
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
      wd('123-Reisen|COM', '123-reisen|k', '123|x+', 'reisen|v+', 'reise|s+'),
      wd('abc123-Reisen|COM', 'abc123-reisen|k', 'abc123|x+', 'reisen|v+', 'reise|s+'),
      wd('Reisen-24|?'),
      wd('Reisen-123|COM', 'reisen-123|k', 'reisen|v+', 'reise|s+', '123|x+'),
      wd('Reisen-24-Seite|COM', 'reisen-24-seite|k', 'reisen-24|x+', 'seite|s+'),
      wd('Reisen-123-Seite|COM', 'reisen-123-seite|k', 'reisen|v+', 'reise|s+', '123|x+', 'seite|s+')
    ])
  end

end
