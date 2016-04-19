# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeTextWriter < AttendeeTestCase

  def setup
    @input = [
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
      ai('EOF|test/test.txt'),
      ai('EOT|')
    ]
  end

  def test_basic
    meet({ 'ext' => 'tst', 'sep' => ',' }, @input)

    assert_equal([
      "Dies,ist,eine,Zeile,.\n", "Dies,ist,eine,zweite,Zeile,.\n"
    ], readlines('test.tst'))
  end

  def test_format
    meet({ 'ext' => '%c-%l.tst', 'sep' => ',' }, @input)

    assert_equal([
      "Dies,ist,eine,Zeile,.\n", "Dies,ist,eine,zweite,Zeile,.\n"
    ], readlines('test.lingo-de.tst'))
  end

  def test_complex
    meet({ 'ext' => 'yip', 'sep' => '-' }, @input)

    assert_equal([
      "Dies-ist-eine-Zeile-.\n", "Dies-ist-eine-zweite-Zeile-.\n"
    ], readlines('test.yip'))
  end

  def test_crlf
    meet({ 'sep' => "\n" }, @input)

    assert_equal([
      "Dies\n", "ist\n", "eine\n", "Zeile\n", ".\n", "Dies\n", "ist\n", "eine\n", "zweite\n", "Zeile\n", ".\n"
    ], readlines('test.txt2'))
  end

  def test_lir_file
    meet({ 'ext' => 'vec', 'lir-format' => false }, [
      ai('LIR|'), ai('FILE|test/lir.txt'),
      ai('RECORD|00237'),
      '020: GERHARD.',
      '025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
      "056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.",
      ai('RECORD|00238'),
      '020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
      "025: das DFG-Projekt GERHARD.",
      ai('RECORD|00239'),
      '020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.',
      "056: \"Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.",
      ai('EOF|test/lir.txt'),
      ai('EOT|')
    ])

    assert_equal([
      "00237*020: GERHARD. 025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressour\
cen. 056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.\n",
      "00238*020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen. 025: das D\
FG-Projekt GERHARD.\n",
      "00239*020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter. 056: \"Das Buch ist ein praxisbezogenes VADEMECUM\
 für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.\n"
    ], readlines('lir.vec'))
  end

  def test_nonewords
    meet({ 'ext' => 'non', 'sep' => "\n" }, [
      ai('FILE|test/text.txt'), 'Nonwörter', 'Nonsense', ai('EOF|test/text.txt'), ai('EOT|')
    ])

    assert_equal([
      "Nonwörter\n", "Nonsense"
    ], readlines('text.non'))
  end

  private

  def readlines(file)
    File.readlines("test/#{file}", encoding: Lingo::ENCODING)
  end

end
