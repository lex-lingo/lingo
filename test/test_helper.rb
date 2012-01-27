# encoding: utf-8

require 'test/unit'
require 'lingo'

class LingoTestCase <  Test::Unit::TestCase

  unless const_defined?(:TEST_FILE)
    TEST_FILE = 'test/de/test.txt'
    dir, name = File.split(TEST_FILE)
    TEST_GLOB = "{#{dir}/,store/#{File.basename(dir)}/}#{name.chomp('.txt')}*"
  end

  def cleanup_store
    Dir[TEST_GLOB].each { |f| File.unlink(f) }
  end

  def split( text )
    text =~ /^([^|]+)\|([^|]*)$/
    [$1.nil? ? '' : $1, $2.nil? ? '' : $2]
  end

  # Erzeugt ein AgendaItem-Objekt
  def ai( text )
    c, p = split( text )
    Lingo::AgendaItem.new( c, p )
  end

  # Erzeugt ein Token-Objekt
  def tk( text )
    f, a = split( text )
    Lingo::Language::Token.new( f, a )
  end

  # Erzeugt ein Lexical-Objekt
  def lx( text )
    f, a = split( text )
    Lingo::Language::Lexical.new( f, a )
  end

  # Erzeugt ein Word-Objekt
  def wd( text, *lexis )
    f, a = split( text )
    w = Lingo::Language::Word.new( f, a )
    lexis.each do |text|
      f, a = split( text )
      w << Lingo::Language::Lexical.new( f, a )
    end
    w
  end

end

class AttendeeTestCase < LingoTestCase

  def initialize(fname)
    super

    @attendee = $1 if self.class.to_s =~ /TestAttendee(.*)/
    @lingo, @output = Lingo.new, []
  end

  def meet(att_cfg, check = true)
    cfg = { 'name' => @attendee.camelcase }
    cfg.update('in'  => 'input')  if @input
    cfg.update('out' => 'output') if @output
    cfg.update(att_cfg)

    @output.clear
    @lingo.reset

    list = [{ @attendee => cfg }]
    list.unshift 'TestSpooler' => { 'out' => 'input',  'input'  => @input  } if @input
    list.push    'TestDumper'  => { 'in'  => 'output', 'output' => @output } if @output

    @lingo.invite(list)
    @lingo.start

    assert_equal(@expect, @output) if check
  end

end

class Lingo
  class Attendee
    class TestSpooler < self

      protected

      def init
        @input = get_key('input')
      end

      def control(cmd, param)
        @input.each(&method(:forward)) if cmd == STR_CMD_TALK
      end

    end

    class TestDumper < self

      protected

      def init
        @output = get_key('output')
      end

      def control(cmd, param)
        @output << AgendaItem.new(cmd, param)
      end

      def process(obj)
        @output << obj
      end

    end
  end
end
