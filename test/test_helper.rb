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

  def split(t)
    t =~ /^([^|]+)\|([^|]*)$/
    [$1 || '', $2 || '']
  end

  def ai(t)
    Lingo::AgendaItem.new(*split(t))
  end

  def tk(t)
    Lingo::Language::Token.new(*split(t))
  end

  def lx(t)
    Lingo::Language::Lexical.new(*split(t))
  end

  def wd(t, *l)
    l.each_with_object(Lingo::Language::Word.new(*split(t))) { |v, w| w << lx(v) }
  end

end

class AttendeeTestCase < LingoTestCase

  def initialize(_)
    super
    @lingo, @output, @input = Lingo.new, [], nil
    @attendee = self.class.to_s[/TestAttendee(.*)/, 1]
  end

  def meet(att_cfg, check = true)
    cfg = { 'name' => @attendee }
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
