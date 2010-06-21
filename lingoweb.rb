#! /usr/bin/ruby

# Usage:
#
#   ruby lingoweb.rb [-p <port>]
#
# or:
#
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

CREDS = if File.readable?(AUTH)
  File.read(AUTH).chomp.split(':', 2)
else
  require 'highline/import'

  user = ask('Enter user name [Leave empty to allow anyone]: ')

  unless user.empty?
    pass = ask('Enter password: ') { |q| q.echo = false }

    File.open(AUTH, 'w') { |f| f.puts [user, pass].join(':') }
    [user, pass]
  else
    []
  end
end

use(Rack::Auth::Basic) { |*creds| creds == CREDS } unless CREDS.empty?

before do
  @in   = params[:in]
  @lang = params[:lang]
  @lang = LANGS.first unless LANGS.include?(@lang)

  @success = true
end

[:get, :post].each { |method| send(method, '/') { doit } }

def doit
  if @lang && @in && !@in.empty?
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
  <title>lingo - "linguistisches lego"</title>
  <style type="text/css">
    a img     { border: none; }
    form      { white-space: nowrap; }
    fieldset  { display: inline; width: 47.7%; }
    textarea  { width: 98.9%; height: 30em; }
    #footer   { border-style: solid; border-color: black; border-width: 1px 0; padding: 2px 4px; }
    #footer a { font-weight: bold; }
    a:link, a:visited { text-decoration: none; color: #F35327; }
    fieldset, #footer { background-color: #F0F0F0; }
    fieldset.error    { background-color: #FDB331; }
  </style>
</head>
<body>
  <a href="http://lex-lingo.de">
    <img src="http://4.bp.blogspot.com/_1bYyjxDS6YA/RvfpL2_LjbI/AAAAAAAAADY/XOKwKgE6pRg/s1600/lingo.png"
         alt="lingo - &quot;linguistisches lego&quot;" />
  </a>

  <form action="/" method="post">
    <fieldset><legend><strong>Input</strong></legend>
      <textarea name="in"><%= @in %></textarea>
    </fieldset>

  <% if @success %>
    <fieldset><legend><strong>Output</strong></legend>
      <textarea readonly="readonly"><%= @out %></textarea>
    </fieldset>
  <% else %>
    <fieldset class="error"><legend><strong>Error</strong></legend>
      <textarea readonly="readonly"><%= @err %></textarea>
    </fieldset>
  <% end %>

    <br />

    <strong>Language</strong> = <select name="lang">
    <% for lang in LANGS %>
      <option value="<%= lang %>"<%= 'selected="selected"' if lang == @lang %>><%= lang %></option>
    <% end %>
    </select>

    <br />
    <br />

    <input type="submit" value="Start processing..."></input> |
    <input type="reset" value="Reset form"></input> |
    <a href="/">New request</a>
  </form>

  <br />

  <div id="footer">
    <em>powered by</em> <a href="http://lex-lingo.de">lingo</a>
    <em>and</em> <a href="http://www.sinatrarb.com">sinatra</a>
  </div>
</body>
</html>
