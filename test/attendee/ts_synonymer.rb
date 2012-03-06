# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeSynonymer < AttendeeTestCase

  def test_basic
    meet({ 'source' => 'sys-syn', 'check' => '-,MUL' }, [
      wd('abtastzeiten|IDF', 'abtastzeit|s')
    ], [
      wd('abtastzeiten|IDF', 'abtastzeit|s', 'abtastfrequenz|y', 'abtastperiode|y')
    ])
  end

  def test_first
    meet({ 'source' => 'sys-syn,tst-syn', 'check' => '-,MUL', 'mode' => 'first' }, [
      wd('Aktienanleihe|IDF', 'aktienanleihe|s')
    ], [
      wd('Aktienanleihe|IDF', 'aktienanleihe|s', 'aktien-anleihe|y', 'reverse convertible bond|y', 'reverse convertibles|y')
    ])
  end

  def test_all
    meet({ 'source' => 'sys-syn,tst-syn', 'check' => '-,MUL', 'mode' => 'all' }, [
      wd('Kerlchen|IDF', 'kerlchen|s')
    ], [
      wd('Kerlchen|IDF', 'kerlchen|s', 'kerlchen|y', 'zwerg-nase|y')
    ])
  end

end
