#! /usr/bin/ruby

# Usage:
#   ruby lingoweb.rb [-p <port>]
#
# or:
#   rackup [-p <port>] lingoweb.rb

require 'rubygems'
require 'sinatra'
require 'open4'

LINGO = File.expand_path(File.dirname(__FILE__))
AUTH  = File.join(LINGO, 'lingoweb.auth')

CMD = '/usr/bin/ruby lingo.rb -c %s -l %s'
CFG = 'lingoweb-%s.cfg'

LANGS = Dir["#{LINGO}/*.lang"].map { |path|
  lang = path[%r{.*/(\w+)\.}, 1]
  lang if File.readable?("#{LINGO}/#{CFG % lang}")
}.compact.sort

abort "No *.lang with corresponding #{CFG % '<lang>'}!" if LANGS.empty?

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
  @in   = params[:in] || ''
  @lang = params[:lang]
  @lang = LANGS.first unless LANGS.include?(@lang)

  @success = true
end

get '' do
  redirect url_for('/')
end

get '/' do
  doit
end

post '/' do
  doit
end

helpers do
  def url_for(path)
    "#{request.script_name}#{path}"
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

__END__

@@ index
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  <title>lingo-web - automatic indexing online</title>
  <style type="text/css">
    a img      { border: none; }
    form       { white-space: nowrap; }
    fieldset   { display: inline; width: 47%; }
    textarea   { width: 98.9%; height: 30em; background-color: white; }
    #welcome   { font-size: 90%; color: #333333; margin-bottom: 0.5em; text-align: center; }
    #legend    { font-size: 75%; color: #333333; margin-bottom: 0.5em; }
    #legend th { font-size: 110%; font-weight: normal; font-family: monospace; text-align: left; }
    #legend td { padding-left: 1em; }
    #footer    { border-style: solid; border-color: black; border-width: 1px 0; padding: 2px 4px; }
    #footer a  { font-weight: bold; }
    a:link, a:visited { text-decoration: none; color: #F35327; }
    fieldset, #footer { background-color: #DFDFDF; }
    fieldset.error    { background-color: #FDB331; }
  </style>
</head>
<body>
  <div id="header">
    <a href="http://lex-lingo.de">
      <img src="http://4.bp.blogspot.com/_1bYyjxDS6YA/RvfpL2_LjbI/AAAAAAAAADY/XOKwKgE6pRg/s1600/lingo.png" alt="lingo" />
    </a>
  </div>

  <div id="welcome">
    <strong>Willkommen bei lingo-web!</strong>
    Lingo-web bietet die Möglichkeit, die Funktionsweise von
    <a href="http://lex-lingo.de">lingo</a> zu testen.<br />
    Lingo ist ein frei verfügbares System zur linguistisch und statistisch
    basierten automatischen Indexierung des Deutschen und Englischen.
  </div>

  <div id="main">
    <form action="<%= url_for '/' %>" method="post">
      <div>
        <fieldset><legend><strong>Input</strong></legend>
          <textarea name="in" rows="20" cols="50"><%= @in %></textarea>
        </fieldset>

      <% if @success %>
        <fieldset><legend><strong>Output</strong></legend>
          <textarea readonly="readonly" rows="20" cols="50"><%= @out %></textarea>
        </fieldset>
      <% else %>
        <fieldset class="error"><legend><strong>Error</strong></legend>
          <textarea readonly="readonly" rows="20" cols="50"><%= @err %></textarea>
        </fieldset>
      <% end %>

        <br />

        <strong>Language</strong> = <select name="lang">
        <% for lang in LANGS %>
          <option value="<%= lang %>"<%= ' selected="selected"' if lang == @lang %>><%= lang %></option>
        <% end %>
        </select>

        <br />
        <br />

        <input type="submit" value="Start processing..."></input> |
        <input type="reset" value="Reset form"></input> |
        <a href="<%= url_for '/' %>">New request</a>
      </div>
    </form>

    <br />
  </div>

  <div id="legend">
    <strong>Legende</strong>:
    <table>
      <tr><th>s</th><td>Substantiv</td></tr>
      <tr><th>a</th><td>Adjektiv</td></tr>
      <tr><th>v</th><td>Verb</td></tr>
      <tr><th>e</th><td>Eigenname</td></tr>
      <tr><th>w</th><td>Wortklasse ohne Suffixe</td></tr>
      <tr><th>t</th><td>Wortklasse ohne Suffixe (z.B. Hochfrequenzterme)</td></tr>
      <tr><th>y</th><td>Synonym</td></tr>
      <tr><th>q (=SEQ)</th><td>Sequenz (algorithmisch erkannter Mehrwortbegriff)</td></tr>
      <tr><th>m (=MUL)</th><td>Mehrwortbegriff</td></tr>
      <tr><th>k (=KOM)</th><td>Kompositum</td></tr>
      <tr><th>+</th><td>Kompositum-Bestandteil</td></tr>
      <tr><th>x+</th><td>unbekannter Kompositum-Bestandteil einer Bindestrich-Konstruktion</td></tr>
      <tr><th>?</th><td>unbekanntes Wort</td></tr>
      <tr><th>MU?</th><td>Mehrwortbestandteil (unbekanntes Wort)</td></tr>
      <tr><th>HELP</th><td>z.B. unbekanntes Sonderzeichen</td></tr>
      <tr><th>ABRV</th><td>mögliche Abk. mit eingeschlossenem Punkt (z.B. "Ausst.Kat")</td></tr>
      <tr><th>PUNC</th><td>Satzzeichen etc.</td></tr>
      <tr><th>OTHR</th><td>Sonstiges Zeichen</td></tr>
      <tr><th>URLS</th><td>URL</td></tr>
      <tr><th>NUMS</th><td>Zahl</td></tr>
    </table>
  </div>

  <div id="footer">
    <em>powered by</em> <a href="http://lex-lingo.de">lingo</a>
    <em>and</em> <a href="http://www.sinatrarb.com">sinatra</a>
  </div>
</body>
</html>
