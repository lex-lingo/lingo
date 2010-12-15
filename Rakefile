# encoding: utf-8

require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/rdoctask'

require 'rbconfig'

require './lib/diff/lcs'
require './lib/diff/lcs/ldiff'

PACKAGE_NAME  = 'lingo'
LINGO_VERSION = '1.6.12'
PACKAGE_PATH  = "pkg/#{PACKAGE_NAME}-#{LINGO_VERSION}"

# Diese Dateien werden mit dem Aufruf von 'rake clean' gelöscht
# (temporäre Dateien, die nicht dauerhaft benötigt werden)
CLEAN.include(
  'txt/*.{mul,non,seq,syn,ve?,csv}',
  'test/{test.*,text.non}',
  '{,test/}{de,en}/*.rev'
)

# Diese Dateien werden mit dem Aufruf von 'rake clobber' gelöscht
# (Dateien, die auch wieder neu generiert werden können)
CLOBBER.include(
  '{,test/}{de,en}/store', 'doc' ,'pkg/*', PACKAGE_PATH + '.*'
)

# Diese Dateien benötigt Lingo um zu funktionieren
LANG_FILES = [
  '{de,en}.lang', '{de,en}/{lingo-*,user-dic}.txt', 'txt/artikel{,-en}.txt'
]

LINGO_FILES = [
  'lingo.rb', 'lib/**/*.rb', 'lingo{,-all,-call}.cfg', 'lingo.opt',
  'doc/**/*', 'info/gpl-hdr.txt', 'info/*.png', 'lir.cfg', 'txt/lir.txt',
  'porter/*', 'README', 'ChangeLog', 'COPYING', 'Rakefile', 'TODO'
]

TEST_FILES = [
  'test.cfg', 'test/ts_*.rb', 'test/attendee/*.rb', '{de,en}/test_*.txt',
  'test/lir*.txt', 'test/mul.txt', 'test/ref/*', 'test/{de,en}/*'
]

RUBY_CMD = Config::CONFIG['RUBY_INSTALL_NAME']

if RUBY_PLATFORM =~ /mswin|mingw/
  DEV_NULL = 'NUL:'

  EXEEXT = Config::CONFIG['EXEEXT']
  RUBY_CMD += EXEEXT

  ZIP_COMMANDS = ['zip', '7z a']
else
  DEV_NULL = '/dev/null'
end

task :default => :test

desc 'Stelle die aktuelle Version auf Subversion bereit'
task :deploy => [:package, :test_remote] do
  system('svn status') || exit
end

task :package => [:testall, :clean, :checkdoc]

desc 'Packettierung von Lingo'
Rake::PackageTask.new(PACKAGE_NAME, LINGO_VERSION) do |pkg|
  pkg.need_zip = true

  pkg.zip_command = ZIP_COMMANDS.find { |cmd|
    cmd = cmd[/\S+/] << EXEEXT
    break cmd if File.executable?(cmd)

    ENV['PATH'].split(File::PATH_SEPARATOR).find { |dir|
      cand = File.join(File.expand_path(dir), cmd)
      break cand if File.executable?(cand)
    }
  } || ZIP_COMMANDS.first if defined?(ZIP_COMMANDS)

  pkg.package_files.include(LANG_FILES, LINGO_FILES, TEST_FILES)
end

desc 'Erstellen der Dokumentation'
Rake::RDocTask.new do |doc|
  doc.title = 'Lex Lingo - RDoc Dokumentation'
  doc.options = [ '--charset', 'UTF-8' ]
  doc.rdoc_dir = 'doc'
  doc.rdoc_files.include('README', 'ChangeLog', 'TODO', 'lib/attendee/*.rb')
end

task :checkdoc do
  docfile = File.join(File.dirname(__FILE__), 'doc', 'index.html')
  abort "Run 'rake rdoc' first." unless File.exists?(docfile)
end

desc 'Vollständiger Test der Lingo-Funktionalität'
task :testall => [:test, :test_txt, :test_lir]

desc 'Testen des Lingo-Core'
Rake::TestTask.new(:test) do |tst|
  tst.test_files = FileList.new('test/ts_*.rb', 'test/attendee/ts_*.rb')
end

desc 'Vollständiges Testen der Lingo-Prozesse anhand einer Textdatei'
task :test_txt do
  # => Testlauf mit normaler Textdatei
  test_ref('artikel', 'test')
end

desc 'Vollständiges Testen der Lingo-Prozesse anhand einer LIR-Datei'
task :test_lir do
  # => Testlauf mit LIR-Datei
  test_ref('lir')
end

desc 'Vollständiges Testen der fertig packettierten Lingo-Version'
task :test_remote => [:package] do
  chdir(PACKAGE_PATH) {
    # => Testlauf im Package-Verzeichnis
    system('rake testall') || exit
  }
end

def test_ref(name, cfg = name)
  system("#{RUBY_CMD} lingo.rb -c #{cfg} txt/#{name}.txt >#{DEV_NULL}") or exit 1

  continue = 0

  # => Für jede vorhandene _ref-Dateien sollen die Ergebnisse verglichen werden
  Dir["test/ref/#{name}.*"].each { |ref|
    org = ref.sub(/test\/ref/, 'txt')
    puts '#' * 60 + "  Teste #{org}"
    continue += Diff::LCS::Ldiff.run(ARGV.clear << org << ref)
  }

  exit 2 unless continue.zero?
end
