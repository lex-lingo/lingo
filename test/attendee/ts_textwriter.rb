# encoding: utf-8

require_relative 'globals'

################################################################################
#
#    Attendee Textwriter
#
class TestAttendeeTextwriter < Test::Unit::TestCase

  def setup
    @data = [
      ai('FILE|test/test.txt'),
      wd('Dies|IDF'),
      wd('ist|IDF'),
      wd('eine|IDF'),
      wd('Zeile|IDF'),
      tk('.|PUNC'),
      ai('EOL|test/test.txt'),
      wd('Dies|IDF'),
      wd('ist|IDF'),
      wd('eine|IDF'),
      wd('zweite|IDF'),
      wd('Zeile|IDF'),
      tk('.|PUNC'),
      ai('EOL|test/test.txt'),
      ai('EOF|test/test.txt')
    ]
  end


  def test_basic
    @input = @data
    @expect = [ "Dies,ist,eine,Zeile,.\n", "Dies,ist,eine,zweite,Zeile,.\n" ]
    meet({'ext'=>'tst',  'sep'=>','}, false)

    @output = File.open('test/test.tst', :encoding => ENC).readlines
    assert_equal(@expect, @output)
  end


  def test_complex
    @input = @data
    @expect = [ "Dies-ist-eine-Zeile-.\n", "Dies-ist-eine-zweite-Zeile-.\n" ]
    meet({'ext'=>'yip',  'sep'=>'-'}, false)

    @output = File.open('test/test.yip', :encoding => ENC).readlines
    assert_equal(@expect, @output)
  end


  def test_crlf
    @input = @data
    @expect = [ "Dies\n", "ist\n", "eine\n", "Zeile\n", ".\n", "Dies\n", "ist\n", "eine\n", "zweite\n", "Zeile\n", ".\n" ]
    meet({'sep'=>"\n"}, false)

    @output = File.open('test/test.txt2', :encoding => ENC).readlines
    assert_equal(@expect, @output)
  end


  def test_lir_file
    @input = [
      ai('LIR-FORMAT|'), ai('FILE|test/lir.txt'),
      ai('RECORD|00237'),
      '020: GERHARD.',
      '025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
      "056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.\r",
      ai('RECORD|00238'),
      '020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
      "025: das DFG-Projekt GERHARD.\r",
      ai('RECORD|00239'),
      '020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.',
      "056: \"Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.\r",
      ai('EOF|test/lir.txt')
    ]
    @expect = [
      "00237*020: GERHARD. 025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressour\
cen. 056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.\r\n",
      "00238*020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen. 025: das D\
FG-Projekt GERHARD.\r\n",
      "00239*020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter. 056: \"Das Buch ist ein praxisbezogenes VADEMECUM\
 für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.\r\n"
    ]
    meet({'ext'=>'csv', 'lir-format'=>nil}, false)

    @output = File.open('test/lir.csv', :encoding => ENC).readlines
    assert_equal(@expect, @output)
  end


  def test_nonewords
    @input = [ai('FILE|test/text.txt'), 'Nonwörter', 'Nonsense', ai('EOF|test/text.txt')]
    @expect = [ "Nonwörter\n", "Nonsense" ]
    meet({'ext'=>'non', 'sep'=>"\n"}, false)

    @output = File.open('test/text.non', :encoding => ENC).readlines
    assert_equal(@expect, @output)
  end

end
#
################################################################################
