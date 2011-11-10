# encoding: utf-8

__DIR__ = File.expand_path('..', __FILE__)

require 'rake/clean'
require File.join(__DIR__, %w[lib lingo version])

PACKAGE_NAME = 'lingo'
PACKAGE_PATH = File.join(__DIR__, 'pkg', "#{PACKAGE_NAME}-#{Lingo::VERSION}")

if RUBY_PLATFORM =~ /msdos|mswin|djgpp|mingw|windows/i
  ZIP_COMMANDS = ['zip', '7z a']  # for hen's gem task
end

task :default => :spec
task :package => [:checkdoc, 'test:all', :clean]

begin
  require 'hen'

  Hen.lay! {{
    :rubyforge => {
      :package => PACKAGE_NAME
    },

    :gem => {
      :name         => PACKAGE_NAME,
      :version      => Lingo::VERSION,
      :summary      => 'The full-featured automatic indexing system',
      :authors      => ['John Vorhauer', 'Jens Wille'],
      :email        => ['john@vorhauer.de', 'jens.wille@uni-koeln.de'],
      :homepage     => 'http://lex-lingo.de',
      :extra_files  => FileList[
        'lingo.rb', 'lingo{,-all,-call}.cfg', 'lingo.opt', 'doc/**/*',
        '{de,en}.lang', '{de,en}/{lingo-*,user-dic}.txt', 'txt/artikel{,-en}.txt',
        'info/gpl-hdr.txt', 'info/*.png', 'lir.cfg', 'txt/lir.txt', 'porter/*',
        'test.cfg', '{de,en}/test_*.txt'
      ].to_a,
      :dependencies => ['unicode'],
      :development_dependencies => [['ruby-nuggets', '>= 0.6.7'], ['diff-lcs', '>= 1.1.3'], 'open4']
    }
  }}
rescue LoadError => err
  warn "Please install the `hen' gem first. (#{err})"
end

CLEAN.include(
  'txt/*.{mul,non,seq,syn,ve?,csv}',
  'test/{test.*,text.non}',
  '{,test/}{de,en}/*.rev'
)

CLOBBER.include(
  '{,test/}{de,en}/store', 'doc' ,'pkg/*', PACKAGE_PATH + '.*'
)

task :checkdoc do
  docfile = File.join(__DIR__, 'doc', 'index.html')
  abort "Please run `rake doc' first." unless File.exists?(docfile)
end

desc 'Run ALL tests'
task 'test:all' => [:test, 'test:txt', 'test:lir']

Rake::TestTask.new(:test) do |t|
  t.ruby_opts << '-rubygems'
  t.test_files = FileList.new('test/ts_*.rb', 'test/attendee/ts_*.rb')
end

desc 'Test against reference file (TXT)'
task 'test:txt' do
  chdir(__DIR__) { test_ref('artikel', 'test') }
end

desc 'Test against reference file (LIR)'
task 'test:lir' do
  chdir(__DIR__) { test_ref('lir') }
end

desc 'Run all tests on packaged distribution'
task 'test:remote' => [:package] do
  chdir(PACKAGE_PATH) { system('rake test:all') } || abort
end

def test_ref(name, cfg = name)
  require 'nuggets/util/ruby'

  require 'diff/lcs'
  require 'diff/lcs/ldiff'

  cmd = %W[lingo.rb -c #{cfg} txt/#{name}.txt]
  continue, msg = 0, ["Command failed: #{cmd.join(' ')}"]

  Process.ruby(*cmd.unshift('-rubygems')) { |_, _, *ios|
    ios.each { |io| msg << io.read }
  }.success? or abort msg.join("\n\n")

  Dir["test/ref/#{name}.*"].each { |ref|
    puts "#{'#' * 60} #{org = ref.sub(/test\/ref/, 'txt')}"
    continue += Diff::LCS::Ldiff.run(ARGV.clear << org << ref)
  }

  exit continue + 1 unless continue.zero?
end
