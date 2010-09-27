# encoding: utf-8

require './test/attendee/globals'

################################################################################
#
#    Attendee Synonymer
#
class TestAttendeeSynonymer < Test::Unit::TestCase

  def test_basic
    @input = [wd('abtastzeiten|IDF', 'abtastzeit|s')]
    @expect = [wd('abtastzeiten|IDF', 'abtastzeit|s', 'abtastfrequenz|y', 'abtastperiode|y')]
    meet({'source'=>'sys-syn', 'check'=>'-,MUL'})
#    @expect.each_index {|i| assert_equal(@expect[i], @output[i]) }
  end


  def test_first
    @input = [wd('Aktienanleihe|IDF', 'aktienanleihe|s')]
    @expect = [wd('Aktienanleihe|IDF', 'aktienanleihe|s', 'aktien-anleihe|y',
      'reverse convertible bond|y', 'reverse convertibles|y')]
    meet({'source'=>'sys-syn,tst-syn', 'check'=>'-,MUL', 'mode'=>'first'})
  end


  def test_all
    @input = [wd('Kerlchen|IDF', 'kerlchen|s')]
    @expect = [wd('Kerlchen|IDF', 'kerlchen|s', 'kerlchen|y', 'zwerg-nase|y')]
    meet({'source'=>'sys-syn,tst-syn', 'check'=>'-,MUL', 'mode'=>'all'})
  end

end
#
################################################################################
