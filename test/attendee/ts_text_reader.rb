# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeTextReader < AttendeeTestCase

  def test_lir_file
    meet({ 'files' => 'test/lir.txt', 'records' => true, 'fields' => false }, nil, [
      ai('LIR|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|00237'),
      li('020: GERHARD.', 25),
      li('025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 140),
      li('056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.', 264),
      li('', 266),
      ai('RECORD|00238'),
      li('020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 391),
      li('025: das DFG-Projekt GERHARD.', 422),
      li('', 424),
      ai('RECORD|00239'),
      li('020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.', 510),
      li('056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.', 634),
      ai("EOF|#{path}"),
      ai('EOT|')
    ])
  end

  def test_lir_file_another_pattern
    meet({ 'files' => 'test/lir2.txt', 'records' => '^\021(\d+)\022', 'fields' => false }, nil, [
      ai('LIR|'), ai("FILE|#{path = File.expand_path('test/lir2.txt')}"),
      ai('RECORD|00237'),
      li('020: GERHARD.', 24),
      li('025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 139),
      li('056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.', 263),
      li('', 265),
      ai('RECORD|00238'),
      li('020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 389),
      li('025: das DFG-Projekt GERHARD.', 420),
      li('', 422),
      ai('RECORD|00239'),
      li('020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.', 507),
      li('056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.', 631),
      ai("EOF|#{path}"),
      ai('EOT|')
    ])
  end

  def test_lir_file_no_capture
    meet({ 'files' => 'test/lir.txt', 'records' => '^\[\d+\.\]', 'fields' => false }, nil, [
      ai('LIR|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|[00237.]'),
      li('020: GERHARD.', 25),
      li('025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 140),
      li('056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.', 264),
      li('', 266),
      ai('RECORD|[00238.]'),
      li('020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 391),
      li('025: das DFG-Projekt GERHARD.', 422),
      li('', 424),
      ai('RECORD|[00239.]'),
      li('020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.', 510),
      li('056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.', 634),
      ai("EOF|#{path}"),
      ai('EOT|')
    ])
  end

  def test_lir_file_fields
    meet({ 'files' => 'test/lir.txt', 'records' => true }, nil, [
      ai('LIR|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|00237'),
      li('GERHARD.', 25),
      li('Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 140),
      li('Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.', 264),
      li('', 266),
      ai('RECORD|00238'),
      li('Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 391),
      li('das DFG-Projekt GERHARD.', 422),
      li('', 424),
      ai('RECORD|00239'),
      li('Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.', 510),
      li('"Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.', 634),
      ai("EOF|#{path}"),
      ai('EOT|')
    ])
  end

  def test_lir_file_fields_another_pattern
    meet({ 'files' => 'test/lir.txt', 'records' => true, 'fields' => '^\d+:' }, nil, [
      ai('LIR|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|00237'),
      li(' GERHARD.', 25),
      li(' Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 140),
      li(' Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.', 264),
      li('', 266),
      ai('RECORD|00238'),
      li(' Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 391),
      li(' das DFG-Projekt GERHARD.', 422),
      li('', 424),
      ai('RECORD|00239'),
      li(' Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.', 510),
      li(' "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.', 634),
      ai("EOF|#{path}"),
      ai('EOT|')
    ])
  end

  def test_lir_file_fields_no_capture
    meet({ 'files' => 'test/lir.txt', 'records' => '^\[\d+\.\]' }, nil, [
      ai('LIR|'), ai("FILE|#{path = File.expand_path('test/lir.txt')}"),
      ai('RECORD|[00237.]'),
      li('GERHARD.', 25),
      li('Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 140),
      li('Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.', 264),
      li('', 266),
      ai('RECORD|[00238.]'),
      li('Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 391),
      li('das DFG-Projekt GERHARD.', 422),
      li('', 424),
      ai('RECORD|[00239.]'),
      li('Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.', 510),
      li('"Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.', 634),
      ai("EOF|#{path}"),
      ai('EOT|')
    ])
  end

  def test_lir_file_bom
    meet({ 'files' => 'test/lir3.txt', 'records' => true, 'fields' => false }, nil, [
      ai('LIR|'), ai("FILE|#{path = File.expand_path('test/lir3.txt')}"),
      ai('RECORD|00237'),
      li('020: GERHARD.', 28),
      li('025: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 143),
      li('056: Die intellektuelle Erschließung des Internet befindet sich in einer Krise. GERHARD ist derzeit weltweit der einzige.', 267),
      li('', 269),
      ai('RECORD|00238'),
      li('020: Automatisches Sammeln, Klassifizieren und Indexieren von wissenschaftlich relevanten Informationsressourcen.', 394),
      li('025: das DFG-Projekt GERHARD.', 425),
      li('', 427),
      ai('RECORD|00239'),
      li('020: Information Retrieval und Dokumentmanagement im Multimedia-Zeitalter.', 513),
      li('056: "Das Buch ist ein praxisbezogenes VADEMECUM für alle, die in einer Welt der Datennetze Wissen/Informationen sammeln.', 637),
      ai("EOF|#{path}"),
      ai('EOT|')
    ])
  end

  def test_normal_file
    meet({ 'files' => 'test/mul.txt' }, nil, [
      ai("FILE|#{path = File.expand_path('test/mul.txt')}"),
      ['Die abstrakte Kunst ist schön.', 31],
      ai("EOF|#{path}"),
      ai('EOT|')
    ])
  end

end
