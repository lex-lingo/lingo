require_relative 'lib/lingo'

Lingo.new(*ARGV).talk if $0 == __FILE__
