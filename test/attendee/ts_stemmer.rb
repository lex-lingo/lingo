# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeStemmer < AttendeeTestCase

  def test_type
    assert_raise(Lingo::NameNotFoundError) { meet({ 'type' => 'bla' }, []) }
  end

  def test_basic
    meet({}, [
      wd('bla|IDF'),
      wd('blub|?'),
      wd('blubs|?'),
      ai('EOF|')
    ], [
      wd('bla|IDF'),
      wd('blub|?'),
      wd('blubs|?', 'blub|z'),
      ai('EOF|')
    ])
  end

  def test_wc
    meet({ 'wordclass' => 'w' }, [
      wd('bla|IDF'),
      wd('blub|?'),
      wd('blubs|?'),
      ai('EOF|')
    ], [
      wd('bla|IDF'),
      wd('blub|?'),
      wd('blubs|?', 'blub|w'),
      ai('EOF|')
    ])
  end

  def test_mode
    meet({ 'mode' => '' }, [
      wd('bla|IDF'),
      wd('a|?'),
      wd('yet|?'),
      wd('blubs|?'),
      ai('EOF|')
    ], [
      wd('bla|IDF'),
      wd('a|?'),
      wd('yet|?'),
      wd('blubs|?', 'blub|z'),
      ai('EOF|')
    ])

    meet({ 'mode' => 'all' }, [
      wd('bla|IDF'),
      wd('a|?'),
      wd('yet|?'),
      wd('blubs|?'),
      ai('EOF|')
    ], [
      wd('bla|IDF'),
      wd('a|?',     'a|z'),
      wd('yet|?',   'yet|z'),
      wd('blubs|?', 'blub|z'),
      ai('EOF|')
    ])
  end

  def test_examples_100
    meet({}, [
      wd('S100|IDF'),
      wd('caresses|?'),
      wd('ponies|?'),
      wd('ties|?'),
      wd('caress|?'),
      wd('cats|?'),
      ai('EOF|')
    ], [
      wd('S100|IDF'),
      wd('caresses|?', 'caress|z'),
      wd('ponies|?',   'poni|z'),
      wd('ties|?',     'ti|z'),      # snowball: tie
      wd('caress|?',   'caress|z'),
      wd('cats|?',     'cat|z'),
      ai('EOF|')
    ])
  end

  def test_examples_110
    meet({ 'mode' => 'all' }, [
      wd('S110|IDF'),
      wd('agreed|?'),
      wd('feed|?'),
      wd('plastered|?'),
      wd('bled|?'),
      wd('motoring|?'),
      wd('sing|?'),
      ai('EOF|')
    ], [
      wd('S110|IDF'),
      wd('agreed|?',    'agre|z'),
      wd('feed|?',      'fe|z'),       # snowball: feed
      wd('plastered|?', 'plaster|z'),
      wd('bled|?',      'bled|z'),
      wd('motoring|?',  'motor|z'),
      wd('sing|?',      'sing|z'),
      ai('EOF|')
    ])
  end

  def test_examples_111
    meet({}, [
      wd('S111|IDF'),
      wd('conflated|?'),
      wd('troubled|?'),
      wd('sized|?'),
      wd('hopping|?'),
      wd('tanned|?'),
      wd('falling|?'),
      wd('hissing|?'),
      wd('fizzed|?'),
      wd('failing|?'),
      wd('filing|?'),
      ai('EOF|')
    ], [
      wd('S111|IDF'),
      wd('conflated|?', 'conflat|z'),
      wd('troubled|?',  'troubl|z'),
      wd('sized|?',     'size|z'),
      wd('hopping|?',   'hop|z'),
      wd('tanned|?',    'tan|z'),
      wd('falling|?',   'fall|z'),
      wd('hissing|?',   'hiss|z'),
      wd('fizzed|?',    'fizz|z'),
      wd('failing|?',   'fail|z'),
      wd('filing|?',    'file|z'),
      ai('EOF|')
    ])
  end

  def test_examples_120
    meet({ 'mode' => 'all' }, [
      wd('S120|IDF'),
      wd('happy|?'),
      wd('sky|?'),
      ai('EOF|')
    ], [
      wd('S120|IDF'),
      wd('happy|?', 'happi|z'),
      wd('sky|?',   'sky|z'),
      ai('EOF|')
    ])
  end

  def test_examples_200
    meet({}, [
      wd('S200|IDF'),
      wd('relational|?'),
      wd('conditional|?'),
      wd('rational|?'),
      wd('valency|?'),
      wd('hesitancy|?'),
      wd('digitizer|?'),
      wd('conformably|?'),
      wd('radically|?'),
      wd('differently|?'),
      wd('vilely|?'),
      wd('analogously|?'),
      wd('vietnamization|?'),
      wd('predication|?'),
      wd('operator|?'),
      wd('feudalism|?'),
      wd('decisiveness|?'),
      wd('hopefulness|?'),
      wd('callousness|?'),
      wd('formality|?'),
      wd('sensitivity|?'),
      wd('sensibility|?'),
      ai('EOF|')
    ], [
      wd('S200|IDF'),
      wd('relational|?',     'relat|z'),
      wd('conditional|?',    'condit|z'),
      wd('rational|?',       'ration|z'),
      wd('valency|?',        'valenc|z'),
      wd('hesitancy|?',      'hesit|z'),
      wd('digitizer|?',      'digit|z'),
      wd('conformably|?',    'conform|z'),
      wd('radically|?',      'radic|z'),
      wd('differently|?',    'differ|z'),
      wd('vilely|?',         'vile|z'),
      wd('analogously|?',    'analog|z'),
      wd('vietnamization|?', 'vietnam|z'),
      wd('predication|?',    'predic|z'),
      wd('operator|?',       'oper|z'),
      wd('feudalism|?',      'feudal|z'),
      wd('decisiveness|?',   'decis|z'),
      wd('hopefulness|?',    'hope|z'),
      wd('callousness|?',    'callous|z'),
      wd('formality|?',      'formal|z'),
      wd('sensitivity|?',    'sensit|z'),
      wd('sensibility|?',    'sensibl|z'),
      ai('EOF|')
    ])
  end

  def test_examples_300
    meet({}, [
      wd('S300|IDF'),
      wd('triplicate|?'),
      wd('formative|?'),
      wd('formalize|?'),
      wd('electricity|?'),
      wd('electrical|?'),
      wd('hopeful|?'),
      wd('goodness|?'),
      ai('EOF|')
    ], [
      wd('S300|IDF'),
      wd('triplicate|?',  'triplic|z'),
      wd('formative|?',   'form|z'),    # snowball: format
      wd('formalize|?',   'formal|z'),
      wd('electricity|?', 'electr|z'),
      wd('electrical|?',  'electr|z'),
      wd('hopeful|?',     'hope|z'),
      wd('goodness|?',    'good|z'),
      ai('EOF|')
    ])
  end

  def test_examples_400
    meet({}, [
      wd('S400|IDF'),
      wd('revival|?'),
      wd('allowance|?'),
      wd('inference|?'),
      wd('airliner|?'),
      wd('gyroscopic|?'),
      wd('adjustable|?'),
      wd('defensible|?'),
      wd('irritant|?'),
      wd('replacement|?'),
      wd('adjustment|?'),
      wd('dependent|?'),
      wd('adoption|?'),
      wd('homologou|?'),
      wd('communism|?'),
      wd('activate|?'),
      wd('angularity|?'),
      wd('homologous|?'),
      wd('effective|?'),
      wd('bowdlerize|?'),
      ai('EOF|')
    ], [
      wd('S400|IDF'),
      wd('revival|?',     'reviv|z'),
      wd('allowance|?',   'allow|z'),
      wd('inference|?',   'infer|z'),
      wd('airliner|?',    'airlin|z'),
      wd('gyroscopic|?',  'gyroscop|z'),
      wd('adjustable|?',  'adjust|z'),
      wd('defensible|?',  'defens|z'),
      wd('irritant|?',    'irrit|z'),
      wd('replacement|?', 'replac|z'),
      wd('adjustment|?',  'adjust|z'),
      wd('dependent|?',   'depend|z'),
      wd('adoption|?',    'adopt|z'),
      wd('homologou|?',   'homolog|z'),   # snowball: homologou
      wd('communism|?',   'commun|z'),    # snowball: communism
      wd('activate|?',    'activ|z'),
      wd('angularity|?',  'angular|z'),
      wd('homologous|?',  'homolog|z'),
      wd('effective|?',   'effect|z'),
      wd('bowdlerize|?',  'bowdler|z'),
      ai('EOF|')
    ])
  end

  def test_examples_500
    meet({ 'mode' => 'all' }, [
      wd('S500|IDF'),
      wd('probate|?'),
      wd('rate|?'),
      wd('cease|?'),
      ai('EOF|')
    ], [
      wd('S500|IDF'),
      wd('probate|?', 'probat|z'),
      wd('rate|?',    'rate|z'),
      wd('cease|?',   'ceas|z'),
      ai('EOF|')
    ])
  end

  def test_examples_510
    meet({ 'mode' => 'all' }, [
      wd('S510|IDF'),
      wd('controll|?'),
      wd('roll|?'),
      ai('EOF|')
    ], [
      wd('S510|IDF'),
      wd('controll|?', 'control|z'),
      wd('roll|?',     'roll|z'),
      ai('EOF|')
    ])
  end

end
