# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeTextReader < AttendeeTestCase

  def test_lir_file
    @expect = [
      ai('LIR-FORMAT|'), ai('FILE|test/lir.txt'),
      ai('RECORD|00237'),
      '020: GERHARD.',
      '025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
      '056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.',
      ai('RECORD|00238'),
      '020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
      '025: das DFG-Projekt GERHARD.',
      ai('RECORD|00239'),
      '020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.',
      '056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.',
      ai('EOF|test/lir.txt')
    ]
    meet({'files'=>'test/lir.txt', 'lir-record-pattern'=>'^\[(\d+)\.\]'})
  end

  def test_lir_file_another_pattern
    @expect = [
      ai('LIR-FORMAT|'), ai('FILE|test/lir2.txt'),
      ai('RECORD|00237'),
      '020: GERHARD.',
      '025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
      '056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.',
      ai('RECORD|00238'),
      '020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.',
      '025: das DFG-Projekt GERHARD.',
      ai('RECORD|00239'),
      '020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.',
      '056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.',
      ai('EOF|test/lir2.txt')
    ]
    meet({'files'=>'test/lir2.txt', 'lir-record-pattern'=>'^\021(\d+)\022'})
  end

  def test_normal_file
    @expect = [
      ai('FILE|test/mul.txt'),
      'Die abstrakte Kunst ist schön.',
      ai('EOF|test/mul.txt')
    ]
    meet({'files'=>'test/mul.txt'})
  end

end
