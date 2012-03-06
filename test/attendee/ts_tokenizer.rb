# encoding: utf-8

class TestAttendeeTokenizer < AttendeeTestCase

  def test_basic
    meet({}, [
      "Dies ist ein Test."
    ], [
      tk('Dies|WORD'), tk('ist|WORD'), tk('ein|WORD'), tk('Test|WORD'), tk('.|PUNC')
    ])
  end

  def test_complex
    meet({}, [
      "1964 www.vorhauer.de bzw. nasenbär, ()"
    ], [
      tk('1964|NUMS'),
      tk('www.vorhauer.de|URLS'),
      tk('bzw|WORD'),
      tk('.|PUNC'),
      tk('nasenbär|WORD'),
      tk(',|PUNC'),
      tk('(|OTHR'),
      tk(')|OTHR')
    ])
  end

end
