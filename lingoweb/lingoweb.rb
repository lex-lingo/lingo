#! /usr/bin/env ruby

# Usage:
#   ruby lingoweb.rb [-p <port>]
#
# or:
#   rackup [-p <port>] lingoweb.rb

require 'sinatra'
require 'nuggets/util/ruby'

LINGOWEB = File.expand_path('..', __FILE__)
LINGO    = File.join(File.dirname(LINGOWEB), 'lingo.rb')
AUTH     = File.join(LINGOWEB, 'lingoweb.auth')
CFG      = File.join(LINGOWEB, 'lingoweb-%s.cfg')

require LINGO

LANGS = Dir["#{File.dirname(LINGO)}/*.lang"].map { |path|
  lang = path[%r{.*/(\w+)\.}, 1]
  lang if File.readable?(CFG % lang)
}.compact.sort

abort "No *.lang with corresponding #{CFG % '<lang>'}!" if LANGS.empty?

UILANGS = %w[en de]

if File.readable?(AUTH)
  CREDS = File.read(AUTH).chomp.split(':', 2)
else
  if STDIN.tty?
    require 'highline/import'

    user = ask('Enter user name [Leave empty to allow anyone]: ')
    pass = ask('Enter password: ') { |q| q.echo = false } unless user.empty?
  end

  CREDS = pass ? [user, pass] : []

  File.write(AUTH, CREDS.join(':'))
end

use Rack::Auth::Basic do |*creds|
  creds == CREDS
end unless CREDS.empty?

before do
  hals = if hal = env['HTTP_ACCEPT_LANGUAGE']
    hal.split(',').map { |l| l.split('-').first.strip } & UILANGS
  else
    []
  end

  @uilang = hals.first || UILANGS.first

  @in   = params[:in]   || ''
  @lang = params[:lang] || @uilang
  @lang = LANGS.first unless LANGS.include?(@lang)

  @success = true
end

get('')   { redirect url_for('/') }
get('/')  { doit }
post('/') { doit }

helpers do
  def url_for(path)
    "#{request.script_name}#{path}"
  end

  def t(*trans)
    i = UILANGS.index(@uilang)
    i && trans[i] || trans.first
  end
end

def doit
  @success = Process.ruby(LINGO, '-c', CFG % @lang, '-l', @lang) { |_, i, o, e|
    IO.interact({ @in => i }, { o => @out = '', e => @err = '' })
  }.success? unless @in.empty?

  erb :index
end

unless $0 == __FILE__  # for rackup
  Lingoweb = Rack::Builder.new { run Sinatra::Application }.to_app
end
