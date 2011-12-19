# encoding: utf-8

require_relative 'globals'

################################################################################
#
#    Attendee Vector_filter
#
class TestAttendeeVector_filter < LingoTestCase

  def setup
    @input = [
      ai('FILE|test'),
      wd('Testwort|IDF', 'substantiv|s', 'adjektiv|a', 'verb|v', 'eigenname|e', 'mehrwortbegriff|m'),
      wd('unknown|?'),
      ai('EOF|test')
    ]
  end


  def test_basic
    @expect = [ai('FILE|test'), 'substantiv', ai('EOF|test')]
    meet({})
  end


  def test_lexicals
    @expect = [ai('FILE|test'), 'adjektiv', 'eigenname', 'substantiv', 'verb', ai('EOF|test')]
    meet({'lexicals'=>'[save]'})
  end


  def test_sort_term_abs
    @expect = [ai('FILE|test'), '1 adjektiv', '1 eigenname', '1 substantiv', '1 verb', ai('EOF|test')]
    meet({'lexicals'=>'[save]', 'sort'=>'term_abs'})
  end


  def test_sort_term_rel
    @expect = [ai('FILE|test'), '0.50000 adjektiv', '0.50000 eigenname', '0.50000 substantiv', '0.50000 verb', ai('EOF|test')]
    meet({'lexicals'=>'[save]', 'sort'=>'term_rel'})
  end

  def test_sort_sto_abs
    @expect = [ai('FILE|test'), 'adjektiv {1}', 'eigenname {1}', 'substantiv {1}', 'verb {1}', ai('EOF|test')]
    meet({'lexicals'=>'[save]', 'sort'=>'sto_abs'})
  end


  def test_sort_sto_rel
    @expect = [ai('FILE|test'), 'adjektiv {0.50000}', 'eigenname {0.50000}', 'substantiv {0.50000}', 'verb {0.50000}', ai('EOF|test')]
    meet({'lexicals'=>'[save]', 'sort'=>'sto_rel'})
  end

  def test_nonword
    @expect = [ai('FILE|test'), 'unknown', ai('EOF|test')]
    meet({'lexicals'=>'\?'})
  end

  def test_nonword_sort_term_abs
    @expect = [ai('FILE|test'), '1 unknown', ai('EOF|test')]
    meet({'lexicals'=>'\?', 'sort'=>'term_abs'})
  end

end
#
################################################################################
