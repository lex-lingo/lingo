# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeTextReader < AttendeeTestCase

  def test_lir_file
    meet({ 'files' => 'test/lir.txt', 'records' => true, 'fields' => false }, nil, [
      ai('LIR-FORMAT|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|00237'),
      li('020: GERHARD.'),
      li('025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.'),
      li(''),
      ai('RECORD|00238'),
      li('020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('025: das DFG-Projekt GERHARD.'),
      li(''),
      ai('RECORD|00239'),
      li('020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.'),
      li('056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.'),
      ai("EOF|#{path}")
    ])
  end

  def test_lir_file_another_pattern
    meet({ 'files' => 'test/lir2.txt', 'records' => '^\021(\d+)\022', 'fields' => false }, nil, [
      ai('LIR-FORMAT|'), ai("FILE|#{path = File.expand_path('test/lir2.txt')}"),
      ai('RECORD|00237'),
      li('020: GERHARD.'),
      li('025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.'),
      li(''),
      ai('RECORD|00238'),
      li('020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('025: das DFG-Projekt GERHARD.'),
      li(''),
      ai('RECORD|00239'),
      li('020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.'),
      li('056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.'),
      ai("EOF|#{path}")
    ])
  end

  def test_lir_file_no_capture
    meet({ 'files' => 'test/lir.txt', 'records' => '^\[\d+\.\]', 'fields' => false }, nil, [
      ai('LIR-FORMAT|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|[00237.]'),
      li('020: GERHARD.'),
      li('025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.'),
      li(''),
      ai('RECORD|[00238.]'),
      li('020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('025: das DFG-Projekt GERHARD.'),
      li(''),
      ai('RECORD|[00239.]'),
      li('020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.'),
      li('056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.'),
      ai("EOF|#{path}")
    ])
  end

  def test_lir_file_fields
    meet({ 'files' => 'test/lir.txt', 'records' => true }, nil, [
      ai('LIR-FORMAT|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|00237'),
      li('GERHARD.'),
      li('Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.'),
      li(''),
      ai('RECORD|00238'),
      li('Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('das DFG-Projekt GERHARD.'),
      li(''),
      ai('RECORD|00239'),
      li('Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.'),
      li('"Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.'),
      ai("EOF|#{path}")
    ])
  end

  def test_lir_file_fields_another_pattern
    meet({ 'files' => 'test/lir.txt', 'records' => true, 'fields' => '^\d+:' }, nil, [
      ai('LIR-FORMAT|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|00237'),
      li(' GERHARD.'),
      li(' Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li(' Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.'),
      li(''),
      ai('RECORD|00238'),
      li(' Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li(' das DFG-Projekt GERHARD.'),
      li(''),
      ai('RECORD|00239'),
      li(' Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.'),
      li(' "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.'),
      ai("EOF|#{path}")
    ])
  end

  def test_lir_file_fields_no_capture
    meet({ 'files' => 'test/lir.txt', 'records' => '^\[\d+\.\]' }, nil, [
      ai('LIR-FORMAT|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|[00237.]'),
      li('GERHARD.'),
      li('Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.'),
      li(''),
      ai('RECORD|[00238.]'),
      li('Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.'),
      li('das DFG-Projekt GERHARD.'),
      li(''),
      ai('RECORD|[00239.]'),
      li('Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.'),
      li('"Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.'),
      ai("EOF|#{path}")
    ])
  end

  def test_normal_file
    meet({ 'files' => 'test/mul.txt' }, nil, [
      ai("FILE|#{path = File.expand_path('test/mul.txt')}"),
      'Die abstrakte Kunst ist schön.',
      ai("EOF|#{path}")
    ])
  end

end
