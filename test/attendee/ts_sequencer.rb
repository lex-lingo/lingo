# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeSequencer < AttendeeTestCase

  def test_basic
    meet({}, [
      # AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|KOM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      ai('EOF|')
    ], [
      # AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      wd('sonne, hell|SEQ', 'sonne, hell|q'),
      # AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|KOM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      wd('sonnenuntergang, schön|SEQ', 'sonnenuntergang, schön|q'),
      ai('EOF|')
    ])
  end

  def test_param
    meet({ 'sequences' => [['SS', '1 2']] }, [
      # (AS)
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      # SS
      wd('Der|IDF', 'der|w'),
      wd('Sonne|IDF', 'sonne|s'),
      wd('Untergang|IDF', 'untergang|s'),
      ai('EOF|')
    ], [
      # (AS)
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('abbild gott|SEQ', 'abbild gott|q'),
      wd('gott turm|SEQ', 'gott turm|q'),
      # SS
      wd('Der|IDF', 'der|w'),
      wd('Sonne|IDF', 'sonne|s'),
      wd('Untergang|IDF', 'untergang|s'),
      wd('sonne untergang|SEQ', 'sonne untergang|q'),
      ai('EOF|')
    ])
  end

  def test_multi
    meet({ 'sequences' => [['MS', '1 2']] }, [
      # MS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      ai('EOF|')
    ], [
      # MS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('abbild gottes turm|SEQ', 'abbild gottes turm|q'),
      ai('EOF|')
    ])
    meet({ 'sequences' => [['MS', '1 2'], ['SS', '1 2']] }, [
      # MS + SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      ai('EOF|')
    ], [
      # MS + SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('abbild gottes turm|SEQ', 'abbild gottes turm|q'),
      wd('abbild gott|SEQ', 'abbild gott|q'),
      wd('gott turm|SEQ', 'gott turm|q'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('abbild gott|SEQ', 'abbild gott|q'),
      ai('EOF|')
    ])
  end

  def test_regex
    meet({ 'sequences' => [['[MS]S', '1 2']] }, [
      # MS + SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      ai('EOF|')
    ], [
      # MS + SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('abbild gottes turm|SEQ', 'abbild gottes turm|q'),
      wd('abbild gott|SEQ', 'abbild gott|q'),
      wd('gott turm|SEQ', 'gott turm|q'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('abbild gott|SEQ', 'abbild gott|q'),
      ai('EOF|')
    ])
  end

  def test_match
    meet({ 'sequences' => [['WA', '1 2 (0)'], ['A[SK]', '0: 2, 1']] }, [
      # WA + AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # WA + AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|KOM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      ai('EOF|')
    ], [
      # WA + AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      wd('die hell (wa)|SEQ', 'die hell (wa)|q'),
      wd('as: sonne, hell|SEQ', 'as: sonne, hell|q'),
      # WA + AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|KOM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      wd('der schön (wa)|SEQ', 'der schön (wa)|q'),
      wd('ak: sonnenuntergang, schön|SEQ', 'ak: sonnenuntergang, schön|q'),
      ai('EOF|')
    ])
  end

end
