# encoding: utf-8

__DIR__ = File.expand_path('..', __FILE__)

require 'rake/clean'
require 'nuggets/ruby'
require File.join(__DIR__, %w[lib lingo version])

PACKAGE_NAME = 'lingo'
PACKAGE_PATH = File.join(__DIR__, 'pkg', "#{PACKAGE_NAME}-#{Lingo::VERSION}")

if RUBY_PLATFORM =~ /msdos|mswin|djgpp|mingw|windows/i
  ZIP_COMMANDS = ['zip', '7z a']  # for hen's gem task
end

task default: :spec
task package: [:checkdoc, 'test:all', :clean]

begin
  require 'hen'

  Hen.lay! {{
    gem: {
      name:         PACKAGE_NAME,
      version:      Lingo::VERSION,
      summary:      'The full-featured automatic indexing system',
      authors:      ['John Vorhauer', 'Jens Wille'],
      email:        ['lingo@vorhauer.de', 'jens.wille@gmail.com'],
      license:      'AGPL',
      homepage:     'http://lex-lingo.de',
      description:  <<-EOT,
Lingo is an open source indexing system for research and teachings.
The main functions of Lingo are:

* identification of (i.e. reduction to) basic word form by means of
  dictionaries and suffix lists
* algorithmic decomposition
* dictionary-based synonymisation and identification of phrases
* generic identification of phrases/word sequences based on patterns
  of word classes
      EOT
      extra_files:  FileList[
        'lingo.rb', 'lingo{,-call}.cfg', 'lir.cfg',
        '{de,en,ru}.lang', '{de,en,ru}/{lingo-*,user-dic,test_*}.txt',
        'txt/{artikel{,-en,-ru},lir}.txt', 'lib/lingo/{srv,web}/**/*'
      ].to_a,
      required_ruby_version: '>= 1.9.2',
      dependencies: [
        'highline',
        ['ruby-nuggets', '>= 0.9.2'],
        'sinatra',
        'sinatra-contrib',
        'unicode'
      ],
      development_dependencies: [
        ['diff-lcs', '>= 1.1.3'],
        'open4'
      ]
    }
  }}
rescue LoadError => err
  warn "Please install the `hen' gem first. (#{err})"
end

CLEAN.include(
  'txt/*.{log,mul,non,seq,ste,syn,ve?}',
  'test/{test.*,text.non}',
  'store/*/*.rev',
  'bench/tmp.*'
)

CLOBBER.include('store')

task :checkdoc do
  docfile = File.join(__DIR__, 'doc', 'index.html')
  abort "Please run `rake doc' first." unless File.exists?(docfile)
end

desc 'Run ALL tests'
task 'test:all' => [:test, 'test:txt', 'test:lir']

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList.new('test/ts_*.rb', 'test/attendee/ts_*.rb')
end

desc 'Test against reference file (TXT)'
task 'test:txt' do
  test_ref('artikel', 'lingo')
end

desc 'Test against reference file (LIR)'
task 'test:lir' do
  test_ref('lir')
end

desc 'Run all tests on packaged distribution'
task 'test:remote' => [:package] do
  chdir(PACKAGE_PATH) { system('rake test:all') } || abort
end

unless (benchmarks = Dir[File.join(__DIR__, 'bench', '*_bench.rb')]).empty?
  desc 'Run all benchmarks'
  task :bench

  benchmarks.each { |benchmark|
    bench = File.basename(benchmark, '_bench.rb')
    task :bench => benchtask = "bench:#{bench}"

    desc "Run #{bench} benchmark"
    task(benchtask) { system(File.ruby, benchmark) }
  }
end

def test_ref(name, cfg = name)
  require 'diff/lcs'
  require 'diff/lcs/ldiff'

  cmd = %W[lingo.rb -c #{cfg} txt/#{name}.txt]
  continue, msg = 0, ["Command failed: #{cmd.join(' ')}"]

  Process.ruby(*cmd) { |_, _, o, e|
    IO.interact({}, { o => msg, e => msg })
  }.success? or abort msg.join("\n\n")

  Dir["test/ref/#{name}.*"].each { |ref|
    puts "## #{org = ref.sub(/test\/ref/, 'txt')}"
    continue += Diff::LCS::Ldiff.run(ARGV.clear << '-a' << org << ref)
  }

  exit continue + 1 unless continue.zero?
end
