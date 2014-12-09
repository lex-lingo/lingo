# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeVectorFilter < AttendeeTestCase

  def setup
    @input = [
      ai('FILE|test'),
      wd('Testwort|IDF', 'substantiv|s', 'adjektiv|a', 'verb|v', 'eigenname|e', 'mehrwortbegriff|m'),
      wd('unknown|?'),
      ai('EOF|test'),
      ai('EOT|')
    ]

    @pos_input = [
      ai('FILE|test'),
      wd('Testwort|IDF', 'substantiv|s', 'adjektiv|a', 'verb|v', 'eigenname|e', 'mehrwortbegriff|m').tap { |w|
        w.instance_variable_set(:@token, tk('Testwort|WORD|0|0'))
      },
      wd('unknown|?').tap { |w|
        w.instance_variable_set(:@token, tk('unknown|WORD|1|8'))
      },
      wd('worttest|IDF', 'adjektiv|a', 'substantiv|s').tap { |w|
        w.instance_variable_set(:@token, tk('worttest|WORD|2|15'))
      },
      wd('notoken|IDF', 'no|a', 'token|s'),
      ai('EOF|test'),
      ai('EOT|')
    ]
  end

  def test_basic
    meet({}, @input, [
      ai('FILE|test'), 'substantiv', ai('EOF|test'), ai('EOT|')
    ])
  end

  def test_dict
    meet({ 'lexicals' => '[save]', 'dict' => true }, @input, [
      ai('FILE|test'), 'testwort,substantiv #s adjektiv #a verb #v eigenname #e', ai('EOF|test'), ai('EOT|')
    ])
  end

  def test_lexicals
    meet({ 'lexicals' => '[save]' }, @input, [
      ai('FILE|test'), 'adjektiv', 'eigenname', 'substantiv', 'verb', ai('EOF|test'), ai('EOT|')
    ])
  end

  def test_sort_term_abs
    meet({ 'lexicals' => '[save]', 'sort' => 'term_abs' }, @input, [
      ai('FILE|test'), '1 adjektiv', '1 eigenname', '1 substantiv', '1 verb', ai('EOF|test'), ai('EOT|')
    ])
  end

  def test_sort_term_rel
    meet({ 'lexicals' => '[save]', 'sort' => 'term_rel' }, @input, [
      ai('FILE|test'), '0.50000 adjektiv', '0.50000 eigenname', '0.50000 substantiv', '0.50000 verb', ai('EOF|test'), ai('EOT|')
    ])
  end

  def test_sort_sto_abs
    meet({ 'lexicals' => '[save]', 'sort' => 'sto_abs' }, @input, [
      ai('FILE|test'), 'adjektiv {1}', 'eigenname {1}', 'substantiv {1}', 'verb {1}', ai('EOF|test'), ai('EOT|')
    ])
  end

  def test_sort_sto_rel
    meet({ 'lexicals' => '[save]', 'sort' => 'sto_rel' }, @input, [
      ai('FILE|test'), 'adjektiv {0.50000}', 'eigenname {0.50000}', 'substantiv {0.50000}', 'verb {0.50000}', ai('EOF|test'), ai('EOT|')
    ])
  end

  def test_nonword
    meet({ 'lexicals' => '\?' }, @input, [
      ai('FILE|test'), 'unknown', ai('EOF|test'), ai('EOT|')
    ])
  end

  def test_nonword_sort_term_abs
    meet({ 'lexicals' => '\?', 'sort' => 'term_abs' }, @input, [
      ai('FILE|test'), '1 unknown', ai('EOF|test'), ai('EOT|')
    ])
  end

  def test_pos
    meet({ 'lexicals' => '[save]', 'pos' => true }, @pos_input, [
      ai('FILE|test'),
      'adjektiv@0:0,2:15',
      'eigenname@0:0',
      'no',
      'substantiv@0:0,2:15',
      'token',
      'verb@0:0',
      ai('EOF|test'),
      ai('EOT|')
    ])
  end

  def test_pos_sort_term_abs
    meet({ 'lexicals' => '[save]', 'pos' => true, 'sort' => 'term_abs' }, @pos_input, [
      ai('FILE|test'),
      '2 adjektiv@0:0,2:15',
      '2 substantiv@0:0,2:15',
      '1 eigenname@0:0',
      '1 no',
      '1 token',
      '1 verb@0:0',
      ai('EOF|test'),
      ai('EOT|')
    ])
  end

  def test_pos_sort_term_rel
    meet({ 'lexicals' => '[save]', 'pos' => true, 'sort' => 'term_rel' }, @pos_input, [
      ai('FILE|test'),
      '0.50000 adjektiv@0:0,2:15',
      '0.50000 substantiv@0:0,2:15',
      '0.25000 eigenname@0:0',
      '0.25000 no',
      '0.25000 token',
      '0.25000 verb@0:0',
      ai('EOF|test'),
      ai('EOT|')
    ])
  end

  def test_pos_sort_sto_abs
    meet({ 'lexicals' => '[save]', 'pos' => true, 'sort' => 'sto_abs' }, @pos_input, [
      ai('FILE|test'),
      'adjektiv@0:0,2:15 {2}',
      'substantiv@0:0,2:15 {2}',
      'eigenname@0:0 {1}',
      'no {1}',
      'token {1}',
      'verb@0:0 {1}',
      ai('EOF|test'),
      ai('EOT|')
    ])
  end

  def test_pos_sort_sto_rel
    meet({ 'lexicals' => '[save]', 'pos' => true, 'sort' => 'sto_rel' }, @pos_input, [
      ai('FILE|test'),
      'adjektiv@0:0,2:15 {0.50000}',
      'substantiv@0:0,2:15 {0.50000}',
      'eigenname@0:0 {0.25000}',
      'no {0.25000}',
      'token {0.25000}',
      'verb@0:0 {0.25000}',
      ai('EOF|test'),
      ai('EOT|')
    ])
  end

  def test_pos_no_sort
    meet({ 'lexicals' => '[save]', 'pos' => true, 'sort' => false }, @pos_input, [
      ai('FILE|test'),
      'substantiv@0:0',
      'adjektiv@0:0',
      'verb@0:0',
      'eigenname@0:0',
      'adjektiv@2:15',
      'substantiv@2:15',
      'no',
      'token',
      ai('EOF|test'),
      ai('EOT|')
    ])
  end

end
