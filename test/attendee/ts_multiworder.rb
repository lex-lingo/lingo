# encoding: utf-8

require_relative 'globals'

################################################################################
#
#    Attendee Multiworder
#
class TestAttendeeMultiworder < Test::Unit::TestCase

  def test_basic
    @input = [
      ai('FILE|mul.txt'),
      #  John_F_._Kennedy
      wd('John|IDF', 'john|e'), wd('F|?'), tk('.|PUNC'), wd('Kennedy|IDF', 'kennedy|e'),
      #  John_F_Kennedy
      wd('John|IDF', 'john|e'), wd('F|?'), wd('Kennedy|IDF', 'kennedy|e'),
      #  John_F_Kennedy_.
      wd('John|IDF', 'john|e'), wd('F|?'), wd('Kennedy|IDF', 'kennedy|e'), tk('.|PUNC'),
      #  a_priori
      wd('a|?'), wd('priori|IDF', 'priori|w'),
      #  Ableitung_nicht_ganzzahliger_Ordnung
      wd('Ableitung|IDF', 'ableitung|s'),
      wd('nicht|IDF', 'nicht|w'),
      wd('ganzzahliger|IDF', 'ganzzahlig|a'),
      wd('Ordnung|IDF', 'ordnung|s'),
      #  Academic_learning_time_in_physical_education
      wd('academic|?'), wd('learning|?'), wd('time|IDF', 'timen|v'),
      wd('in|IDF', 'in|t'), wd('physical|?'), wd('education|?'),
      #  Satzende
      tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      #  John_F_._Kennedy
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      #  John_F_Kennedy
      wd('John F Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      #  John_F_Kennedy_.
      wd('John F Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      tk('.|PUNC'),
      #  a_priori
      wd('a priori|MUL', 'a priori|m'),
      wd('a|MU?'), wd('priori|IDF', 'priori|w'),
      #  Ableitung_nicht_ganzzahliger_Ordnung
      wd('Ableitung nicht ganzzahliger Ordnung|MUL', 'ableitung nicht ganzzahliger ordnung|m'),
      wd('Ableitung|IDF', 'ableitung|s'),
      wd('nicht|IDF', 'nicht|w'),
      wd('ganzzahliger|IDF', 'ganzzahlig|a'),
      wd('Ordnung|IDF', 'ordnung|s'),
      #  Academic_learning_time_in_physical_education
      wd('academic learning time in physical education|MUL', 'academic learning time in physical education|m'),
      wd('academic|MU?'), wd('learning|MU?'), wd('time|IDF', 'timen|v'),
      wd('in|IDF', 'in|t'), wd('physical|MU?'), wd('education|MU?'),
      #  Satzende
      tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})
  end

  def test_multiple_prefix
    @input = [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema|MUL', 'abelsches schema|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

    @input = [
      ai('FILE|mul.txt'),
      wd('Tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      wd('Tolles abelsches Schema|MUL', 'tolles abelsches schema|m'),
      wd('Tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

    @input = [
      ai('FILE|mul.txt'),
      wd('Super|IDF', 'super|a'), wd('tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      wd('Super tolles abelsches Schema|MUL', 'super tolles abelsches schema|m'),
      wd('Super|IDF', 'super|a'), wd('tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

    @input = [
      ai('FILE|mul.txt'),
      wd('Extra|IDF', 'extra|a'), wd('super|IDF', 'super|a'), wd('tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      wd('Extra super tolles abelsches Schema|MUL', 'extra super tolles abelsches schema|m'),
      wd('Extra|IDF', 'extra|a'), wd('super|IDF', 'super|a'), wd('tolles|IDF', 'toll|a'), wd('abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})
  end

  def test_multiple_suffix
    @input = [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema|MUL', 'abelsches schema|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

    @input = [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema toll|MUL', 'abelsches schema toll|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

    @input = [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), wd('super|IDF', 'super|a'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema toll super|MUL', 'abelsches schema toll super|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), wd('super|IDF', 'super|a'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

    @input = [
      ai('FILE|mul.txt'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), wd('super|IDF', 'super|a'), wd('extra|IDF', 'extra|a'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      wd('Abelsches Schema toll super extra|MUL', 'abelsches schema toll super extra|m'),
      wd('Abelsches|IDF', 'abelsch|a'), wd('Schema|IDF', 'schema|s'), wd('toll|IDF', 'toll|a'), wd('super|IDF', 'super|a'), wd('extra|IDF', 'extra|a'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})
  end

  def test_ending_count
    @input = [
      ai('FILE|mul.txt'),
      wd('John|IDF', 'john|e'), wd('F|?'), tk('.|PUNC'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('war|IDF', 'war|w'), wd('einmal|IDF', 'einmal|w'), wd('Präsident|IDF', 'präsident|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    @expect = [
      ai('FILE|mul.txt'),
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('war|IDF', 'war|w'), wd('einmal|IDF', 'einmal|w'), wd('Präsident|IDF', 'präsident|s'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

    #
    @input.delete_at(-3)
    @expect = [
      ai('FILE|mul.txt'),
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('war|IDF', 'war|w'), wd('einmal|IDF', 'einmal|w'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

    #
    @input.delete_at(-3)
    @expect = [
      ai('FILE|mul.txt'),
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      wd('war|IDF', 'war|w'), tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

    #
    @input.delete_at(-3)
    @expect = [
      ai('FILE|mul.txt'),
      wd('John F. Kennedy|MUL', 'john f. kennedy|m'),
      wd('John|IDF', 'john|e'), wd('F|MU?'), wd('Kennedy|IDF', 'kennedy|e'),
      tk('.|PUNC'),
      ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul'})

  end


  def test_two_sources_mode_first
    #  in keinen WB enthalten
    @input = [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul,tst-mu2', 'mode'=>'first'})


    #  im ersten WB enthalten
    @input = [
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'),
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul,tst-mu2', 'mode'=>'first'})


    #  im zweiten WB enthalten
    @input = [
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'),
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul,tst-mu2', 'mode'=>'first'})


    #  in beiden WB enthalten
    @input = [
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('azyklischen Bewegungen|MUL', 'chaotisches movement|m'),
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mul,tst-mu2', 'mode'=>'first'})
  end


  def test_two_sources_mode_first_flipped
    #  in keinen WB enthalten
    @input = [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'first'})

    #  im ersten WB enthalten
    @input = [
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'),
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'first'})

    #  im zweiten WB enthalten
    @input = [
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'),
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'first'})

    #  in beiden WB enthalten
    @input = [
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('azyklischen Bewegungen|MUL', 'azyklische bewegung|m'),
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'first'})
  end


  def test_select_two_sources_mode_all
    #  in keinen WB enthalten
    @input = [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'all'})

    #  im ersten WB enthalten
    @input = [
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'),
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'all'})

    #  im zweiten WB enthalten
    @input = [
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'),
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'all'})

    #  in beiden WB enthalten
    @input = [
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('azyklischen Bewegungen|MUL', 'azyklische bewegung|m', 'chaotisches movement|m'),
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul', 'mode'=>'all'})
  end


  def test_select_two_sources_mode_def
    #  in keinen WB enthalten
    @input = [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('intelligente|IDF', 'intelligent|a'), wd('Indexierung|IDF', 'indexierung|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul'})

    #  im ersten WB enthalten
    @input = [
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('abstrakten Kunst|MUL', 'abstrakte kunst|m'),
      wd('abstrakten|IDF', 'abstrakt|a'), wd('Kunst|IDF', 'kunst|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul'})

    #  im zweiten WB enthalten
    @input = [
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('traumatischer Angelegenheit|MUL', 'traumatische angelegenheit|m'),
      wd('traumatischer|IDF', 'traumatisch|a'), wd('Angelegenheit|IDF', 'angelegenheit|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul'})

    #  in beiden WB enthalten
    @input = [
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
    ]
    @expect = [
      wd('azyklischen Bewegungen|MUL', 'azyklische bewegung|m', 'chaotisches movement|m'),
      wd('azyklischen|IDF', 'azyklisch|a'), wd('Bewegungen|IDF', 'bewegung|s'), ai('EOF|mul.txt')
    ]
    meet({'source'=>'tst-mu2,tst-mul'})
  end

end
#
################################################################################
