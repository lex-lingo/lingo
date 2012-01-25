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
    Lingo::Token.new( f, a )
  end

  # Erzeugt ein Lexical-Objekt
  def lx( text )
    f, a = split( text )
    Lingo::Lexical.new( f, a )
  end

  # Erzeugt ein Word-Objekt
  def wd( text, *lexis )
    f, a = split( text )
    w = Lingo::Word.new( f, a )
    lexis.each do |text|
      f, a = split( text )
      w << Lingo::Lexical.new( f, a )
    end
    w
  end

end

class AttendeeTestCase < LingoTestCase

  def initialize(fname)
    super

    @attendee = $1.downcase if self.class.to_s =~ /TestAttendee(.*)/
    @lingo, @output = Lingo.new, []
  end

  def meet(att_cfg, check=true)
    std_cfg = {'name'=>@attendee.capitalize}
    std_cfg.update({'in'=>'lines'}) unless @input.nil?
    std_cfg.update({'out'=>'output'}) unless @output.nil?

    @output.clear
    @lingo.reset
    inv_list = []
    inv_list << {'helper'=>{'name'=>'Helper', 'out'=>'lines', 'spool_from'=>@input}} unless @input.nil?
    inv_list << {@attendee=>std_cfg.update( att_cfg )}
    inv_list << {'helper'=>{'name'=>'Helper', 'in'=>'output', 'dump_to'=>@output}} unless @output.nil?
    @lingo.invite(inv_list)
    @lingo.start

    assert_equal(@expect, @output) if check
  end

end

class Lingo

  class Attendee::Helper < Attendee

    protected

    def init
      case
        when has_key?('spool_from')
          @spool_from = get_key('spool_from')
          @spooler = true
        when has_key?('dump_to')
          @dump_to = get_key('dump_to')
          @spooler = false
        else
          forward(STR_CMD_ERR, 'Weder dump_to noch spool_from-Attribut abgegeben')
      end
    end

    def control(cmd, param)
      if @spooler
        @spool_from.each { |obj| forward(obj) } if cmd == STR_CMD_TALK
      else
        @dump_to << AgendaItem.new(cmd, param)
      end
    end

    def process(obj)
      @dump_to << obj unless @spooler
    end

  end

end
