# encoding: utf-8

require 'test/unit'
require './lingo'

################################################################################
#
#    Hilfsroutinen für kurze Schreibweisen

def split( text )
  text =~ /^([^|]+)\|([^|]*)$/
  [$1.nil? ? '' : $1, $2.nil? ? '' : $2]
end

#    Erzeugt ein AgendaItem-Objekt
def ai( text )
  c, p = split( text )
  AgendaItem.new( c, p )
end

#    Erzeugt ein Token-Objekt
def tk( text )
  f, a = split( text )
  Token.new( f, a )
end

#    Erzeugt ein Lexical-Objekt
def lx( text )
  f, a = split( text )
  Lexical.new( f, a )
end

#    Erzeugt ein Word-Objekt
def wd( text, *lexis )
  f, a = split( text )
  w = Word.new( f, a )
  lexis.each do |text|
    f, a = split( text )
    w << Lexical.new( f, a )
  end
  w
end

#
################################################################################



################################################################################
#
#    TestCase erweitern für Attendee-Tests
#
class Test::Unit::TestCase

  alias old_init initialize

  def initialize(fname)
    old_init(fname)
    @attendee = $1.downcase if self.class.to_s =~ /TestAttendee(.*)/
    @output = Array.new

    Lingo.new('lingo.rb', [])
  end


  def meet(att_cfg, check=true)
    std_cfg = {'name'=>@attendee.capitalize}
    std_cfg.update({'in'=>'lines'}) unless @input.nil?
    std_cfg.update({'out'=>'output'}) unless @output.nil?

    @output.clear
    Lingo::meeting.reset
    inv_list = []
    inv_list << {'helper'=>{'name'=>'Helper', 'out'=>'lines', 'spool_from'=>@input}} unless @input.nil?
    inv_list << {@attendee=>std_cfg.update( att_cfg )}
    inv_list << {'helper'=>{'name'=>'Helper', 'in'=>'output', 'dump_to'=>@output}} unless @output.nil?
    Lingo::meeting.invite( inv_list )
    Lingo::meeting.start( 0 )

    assert_equal(@expect, @output) if check
  end

end
#
################################################################################

