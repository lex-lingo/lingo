# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeVectorFilter < AttendeeTestCase

  def setup
    @input = [
      ai('FILE|test'),
      wd('Testwort|IDF', 'substantiv|s', 'adjektiv|a', 'verb|v', 'eigenname|e', 'mehrwortbegriff|m'),
      wd('unknown|?'),
      ai('EOF|test')
    ]
  end

  def test_basic
    meet({}, @input, [
      ai('FILE|test'), 'substantiv', ai('EOF|test')
    ])
  end

  def test_lexicals
    meet({ 'lexicals' => '[save]' }, @input, [
      ai('FILE|test'), 'adjektiv', 'eigenname', 'substantiv', 'verb', ai('EOF|test')
    ])
  end

  def test_sort_term_abs
    meet({ 'lexicals' => '[save]', 'sort' => 'term_abs' }, @input, [
      ai('FILE|test'), '1 adjektiv', '1 eigenname', '1 substantiv', '1 verb', ai('EOF|test')
    ])
  end

  def test_sort_term_rel
    meet({ 'lexicals' => '[save]', 'sort' => 'term_rel' }, @input, [
      ai('FILE|test'), '0.50000 adjektiv', '0.50000 eigenname', '0.50000 substantiv', '0.50000 verb', ai('EOF|test')
    ])
  end

  def test_sort_sto_abs
    meet({ 'lexicals' => '[save]', 'sort' => 'sto_abs' }, @input, [
      ai('FILE|test'), 'adjektiv {1}', 'eigenname {1}', 'substantiv {1}', 'verb {1}', ai('EOF|test')
    ])
  end

  def test_sort_sto_rel
    meet({ 'lexicals' => '[save]', 'sort' => 'sto_rel' }, @input, [
      ai('FILE|test'), 'adjektiv {0.50000}', 'eigenname {0.50000}', 'substantiv {0.50000}', 'verb {0.50000}', ai('EOF|test')
    ])
  end

  def test_nonword
    meet({ 'lexicals' => '\?' }, @input, [
      ai('FILE|test'), 'unknown', ai('EOF|test')
    ])
  end

  def test_nonword_sort_term_abs
    meet({ 'lexicals' => '\?', 'sort' => 'term_abs' }, @input, [
      ai('FILE|test'), '1 unknown', ai('EOF|test')
    ])
  end

end
