# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeMultiWorder < AttendeeTestCase

  def test_basic
    meet({ 'source' => 'tst-mul' }, [
      ai('FILE|mul.txt'),
      wd('John|IDF', 'john|e'), wd('F|?'), tk('.|PUNC'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('John|IDF', 'john|e'), wd('F|?'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('John|IDF', 'john|e'), wd('F|?'), wd('Kennedy|IDF', 'kennedy|e'), tk('.|PUNC'),
      wd('a|?'), wd('priori|IDF', 'priori|w'),
      wd('Ableitung|IDF', 'ableitung|s'),
      wd('nicht|IDF', 'nicht|w'),
      wd('ganzzahliger|IDF', 'ganzzahlig|a'),
      wd('Ordnung|IDF', 'ordnung|s'),
      wd('academic|?'), wd('learning|?'), wd('time|IDF', 'timen|v'),
      wd('in|IDF', 'in|t'), wd('physical|?'), wd('education|?'),
      tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('John F Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('John F Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      tk('.|PUNC'),
      wd('a priori|MUL', 'a priori|m'),
      wd('a|MU?'), wd('priori|IDF', 'priori|w'),
      wd('Ableitung nicht ganzzahliger Ordnung|MUL', 'ableitung nicht ganzzahliger ordnung|m'),
      wd('Ableitung|IDF', 'ableitung|s'),
      wd('nicht|IDF', 'nicht|w'),
      wd('ganzzahliger|IDF', 'ganzzahlig|a'),
      wd('Ordnung|IDF', 'ordnung|s'),
      wd('academic learning time in physical education|MUL', 'academic learning time in physical education|m'),
      wd('academic|MU?'), wd('learning|MU?'), wd('time|IDF', 'timen|v'),
      wd('in|IDF', 'in|t'), wd('physical|MU?'), wd('education|MU?'),
      tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])
  end

  def test_multiple_prefix
    meet({ 'source' => 'tst-mul' }, [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema|MUL', 'abelsches schema|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])

    meet({ 'source' => 'tst-mul' }, [
      ai('FILE|mul.txt'),
      wd('Tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('Tolles abelsches Schema|MUL', 'tolles abelsches schema|m'),
      wd('Tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])

    meet({ 'source' => 'tst-mul' }, [
      ai('FILE|mul.txt'),
      wd('Super|IDF', 'super|a'), wd('tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('Super tolles abelsches Schema|MUL', 'super tolles abelsches schema|m'),
      wd('Super|IDF', 'super|a'), wd('tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])

    meet({ 'source' => 'tst-mul' }, [
      ai('FILE|mul.txt'),
      wd('Extra|IDF', 'extra|a'), wd('super|IDF', 'super|a'), wd('tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('Extra super tolles abelsches Schema|MUL', 'extra super tolles abelsches schema|m'),
      wd('Extra|IDF', 'extra|a'), wd('super|IDF', 'super|a'), wd('tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])
  end

  def test_multiple_suffix
    meet({ 'source' => 'tst-mul' }, [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema|MUL', 'abelsches schema|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])

    meet({ 'source' => 'tst-mul' }, [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema toll|MUL', 'abelsches schema toll|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])

    meet({ 'source' => 'tst-mul' }, [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), wd('super|IDF', 'super|a'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema toll super|MUL', 'abelsches schema toll super|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), wd('super|IDF', 'super|a'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])

    meet({ 'source' => 'tst-mul' }, [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), wd('super|IDF', 'super|a'), wd('extra|IDF', 'extra|a'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema toll super extra|MUL', 'abelsches schema toll super extra|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), wd('super|IDF', 'super|a'), wd('extra|IDF', 'extra|a'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])
  end

  def test_ending_count
    meet({ 'source' => 'tst-mul' }, input = [
      ai('FILE|mul.txt'),
      wd('John|IDF', 'john|e'), wd('F|?'), tk('.|PUNC'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('war|IDF', 'war|w'), wd('einmal|IDF', 'einmal|w'), wd('Präsident|IDF', 'präsident|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ], [
      ai('FILE|mul.txt'),
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('war|IDF', 'war|w'), wd('einmal|IDF', 'einmal|w'), wd('Präsident|IDF', 'präsident|s'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])

    input.delete_at(-4)
    meet({ 'source' => 'tst-mul' }, input, [
      ai('FILE|mul.txt'),
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('war|IDF', 'war|w'), wd('einmal|IDF', 'einmal|w'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])

    input.delete_at(-4)
    meet({ 'source' => 'tst-mul' }, input, [
      ai('FILE|mul.txt'),
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('war|IDF', 'war|w'), tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])

    input.delete_at(-4)
    meet({ 'source' => 'tst-mul' }, input, [
      ai('FILE|mul.txt'),
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      tk('.|PUNC'),
      ai('EOF|mul.txt'),
      ai('EOT|')
    ])
  end

  def test_two_sources_mode_first
    meet({ 'source' => 'tst-mul,tst-mu2', 'mode' => 'first' }, [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mul,tst-mu2', 'mode' => 'first' }, [
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'),
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mul,tst-mu2', 'mode' => 'first' }, [
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'),
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mul,tst-mu2', 'mode' => 'first' }, [
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('azyklischen Bewegungen|MUL', 'chaotisches movement|m'),
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])
  end

  def test_two_sources_mode_first_flipped
    meet({ 'source' => 'tst-mu2,tst-mul', 'mode' => 'first' }, [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mu2,tst-mul', 'mode' => 'first' }, [
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'),
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mu2,tst-mul', 'mode' => 'first' }, [
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'),
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mu2,tst-mul', 'mode' => 'first' }, [
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('azyklischen Bewegungen|MUL', 'azyklische bewegung|m'),
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])
  end

  def test_select_two_sources_mode_all
    meet({ 'source' => 'tst-mu2,tst-mul', 'mode' => 'all' }, [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mu2,tst-mul', 'mode' => 'all' }, [
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'),
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mu2,tst-mul', 'mode' => 'all' }, [
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'),
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mu2,tst-mul', 'mode' => 'all' }, [
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('azyklischen Bewegungen|MUL', 'azyklische bewegung|m', 'chaotisches movement|m'),
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])
  end

  def test_select_two_sources_mode_def
    meet({ 'source' => 'tst-mu2,tst-mul' }, [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mu2,tst-mul' }, [
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'),
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mu2,tst-mul' }, [
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'),
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])

    meet({ 'source' => 'tst-mu2,tst-mul' }, [
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ], [
      wd('azyklischen Bewegungen|MUL', 'azyklische bewegung|m', 'chaotisches movement|m'),
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt'), ai('EOT|')
    ])
  end

end
