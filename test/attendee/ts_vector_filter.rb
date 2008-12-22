require 'test/attendee/globals'

################################################################################
#
#    Attendee Vector_filter
#
class TestAttendeeVector_filter < Test::Unit::TestCase

  def setup
    @input = [
      ai('FILE|test'),
      wd('Testwort|IDF', 'substantiv|s', 'adjektiv|a', 'verb|v', 'eigenname|e', 'mehrwortbegriff|m'),
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
    @expect = [ai('FILE|test'), '1.00000 adjektiv', '1.00000 eigenname', '1.00000 substantiv', '1.00000 verb', ai('EOF|test')]
    meet({'lexicals'=>'[save]', 'sort'=>'term_rel'})
  end

  def test_sort_sto_abs
    @expect = [ai('FILE|test'), 'adjektiv {1}', 'eigenname {1}', 'substantiv {1}', 'verb {1}', ai('EOF|test')]
    meet({'lexicals'=>'[save]', 'sort'=>'sto_abs'})
  end


  def test_sort_sto_rel
    @expect = [ai('FILE|test'), 'adjektiv {1.00000}', 'eigenname {1.00000}', 'substantiv {1.00000}', 'verb {1.00000}', ai('EOF|test')]
    meet({'lexicals'=>'[save]', 'sort'=>'sto_rel'})
  end

end
#
################################################################################
