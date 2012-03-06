# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeObjectFilter < AttendeeTestCase

  def test_basic
    meet({ 'objects' => 'obj.form =~ /^[A-Z]/' }, [
      wd('Eins|IDF'), wd('zwei|?'), wd('Drei|IDF'), wd('vier|?'), ai('EOF|')
    ], [
      wd('Eins|IDF'), wd('Drei|IDF'), ai('EOF|')
    ])
  end

end
