#! /usr/bin/ruby

# Usage:
#   ruby lingoweb.rb [-p <port>]
#
# or:
#   rackup [-p <port>] lingoweb.rb

require 'rubygems'
require 'sinatra'
require 'open4'

LINGOWEB = File.expand_path('..', __FILE__)
LINGO    = File.dirname(LINGOWEB)
AUTH     = File.join(LINGOWEB, 'lingoweb.auth')

CMD = '/usr/bin/ruby lingo.rb -c %s -l %s'
CFG = File.join(LINGOWEB, 'lingoweb-%s.cfg')

LANGS = Dir["#{LINGO}/*.lang"].map { |path|
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

  File.open(AUTH, 'w') { |f| f.puts CREDS.join(':') }
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
  unless @in.empty?
    @cmd = CMD % [CFG % @lang, @lang]

    Dir.chdir(LINGO) {
      @success = Open4.popen4(@cmd) { |pid, stdin, stdout, stderr|
        stdin.puts @in
        stdin.close

        @out = stdout.read
        @err = stderr.read
      }.success?
    }
  end

  erb :index
end

unless $0 == __FILE__  # for rackup
  Lingoweb = Rack::Builder.new { run Sinatra::Application }.to_app
end
