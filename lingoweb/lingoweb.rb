#! /usr/bin/env ruby

require 'lingo'
require 'sinatra'
require 'nuggets/util/ruby'

UILANGS = %w[en de]

LANGS = Lingo.list(:lang).map { |l| l[%r{.*/(\w+)\.}, 1] }.sort
abort 'No *.lang!' if LANGS.empty?

base = __FILE__.sub(/\.[^.]*\z/, '')
auth, cfg = base + '.auth', base + '.cfg'

LINGO = Hash.new { |h, k| h[k] = Lingo.call(cfg, ['-l', k]) }

if File.readable?(auth)
  c = File.read(auth).chomp.split(':', 2)
  use(Rack::Auth::Basic) { |*b| b == c } unless c.empty?
end

before do
  @uilang = if hal = env['HTTP_ACCEPT_LANGUAGE']
    hals = hal.split(',').map { |l| l.split('-').first.strip }
    (hals & UILANGS).first
  end || UILANGS.first

  @in   = params[:in]   || ''
  @lang = params[:lang] || @uilang
  @lang = LANGS.first unless LANGS.include?(@lang)
end

get('')   { redirect url_for('/') }
get('/')  { doit }
post('/') { doit }

helpers do
  def url_for(path)
    "#{request.script_name}#{path}"
  end

  def t(*t)
    (i = UILANGS.index(@uilang)) && t[i] || t.first
  end
end

def doit
  @out = LINGO[@lang].talk(@in) { |_| _ }.join("\n") unless @in.empty?
  erb :index
end

unless $0 == __FILE__  # for rackup
  Lingoweb = Rack::Builder.new { run Sinatra::Application }.to_app
end
