# encoding: utf-8

require 'test/unit'
require 'lingo'

warn 'NOTICE: Skipping slow tests...' if ENV['LINGO_DISABLE_SLOW_TESTS']

class LingoTestCase < Test::Unit::TestCase

  unless const_defined?(:TEST_FILE)
    TEST_FILE = 'test/de/test.txt'
    dir, name = File.split(TEST_FILE)
    TEST_GLOB = "{#{dir}/,store/#{File.basename(dir)}/}#{name.chomp('.txt')}*"
  end

  def cleanup_store
    Dir[TEST_GLOB].each { |f| File.delete(f) }
  end

  def split(t, r = '|')
    a, b, *c = t.split(r)
    [a || '', b || '', *c]
  end

  def li(t, o)
    ["#{t}\r\n", o]
  end

  def ai(t)
    i = t.split('|')
    i.unshift(i.shift.to_sym)
  end

  def tk(t)
    a, b, *c = split(t, /\|(?=[A-Z\d])/)
    Lingo::Language::Token.new(a, b, *c.map(&:to_i))
  end

  def lx(t)
    a, b, *c = split(t)
    Lingo::Language::Lexical.new(a, [b, *c])
  end

  def wd(t, *l)
    Lingo::Language::Word.new_lexicals(*split(t), l.map! { |i| lx(i) })
  end

end

class AttendeeTestCase < LingoTestCase

  def initialize(_)
    super
    @lingo, @attendee = Lingo.new, self.class.to_s[/TestAttendee(.*)/, 1]
  end

  def meet(att_cfg, input, expect = nil)
    cfg = { 'name' => @attendee }
    cfg.update('in'  => 'input')  if input
    cfg.update('out' => 'output') if expect
    cfg.update(att_cfg)

    @lingo.reset

    list = [{ @attendee => cfg }]

    list.unshift('TestSpooler' => {
      'out'    => 'input',
      'input'  => input,
      'pos'    => @attendee == 'Tokenizer' }) if input

    list.push('TestDumper' => {
      'in'     => 'output',
      'output' => output = [] }) if expect

    @lingo.invite(list)
    @lingo.start

    assert_equal(expect, output) if expect

    @lingo.reset
  end

end

class Lingo

  class Attendee

    class TestSpooler < self

      def init
        @input, @pos = get_key('input'), get_key('pos', nil) && 0
      end

      def control(cmd)
        if cmd == :TALK
          @input.each { |i| i.is_a?(Array) ? command(*i) :
            @pos ? forward(i, @pos += i.bytesize) : forward(i) }
        end
      end

    end

    class TestDumper < self

      def init
        @output = get_key('output')
      end

      def control(*args)
        @output.push(args)
      end

      def process(obj, *rest)
        @output.push(rest.empty? ? obj : rest.unshift(obj))
      end

    end

  end

  class Database

    alias_method :original_convert, :convert

    def convert(verbose = false)
      original_convert(verbose)
    end

  end

end
