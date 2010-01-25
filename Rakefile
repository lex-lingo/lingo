# encoding: utf-8

require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/rdoctask'

require 'rbconfig'

require 'diff/lcs'
require 'diff/lcs/ldiff'

PACKAGE_NAME = 'lingo'
LINGO_VERSION = '1.6.10'
PACKAGE_PATH = 'pkg/'+PACKAGE_NAME+'-'+LINGO_VERSION+'.zip'

# => CLEAN-FILES
# => Diese Dateien werden mit dem Aufruf von 'rake clean' gelöscht (temporäre Dateien, die nicht dauerhaft benötigt werden)
CLEAN.include( 'txt/*.mul', 'txt/*.non', 'txt/*.seq', 'txt/*.syn', 'txt/*.ve?', 'txt/lir.csv', 'test/test.*', 'test/text.non'  )
CLEAN.include( 'de/*.rev', 'en/*.rev', 'test/de/*.rev' )


# => CLOBBER-FILES
# => Diese Dateien werden mit dem Aufruf von 'rake clobber' gelöscht (Dateien, die auch wieder neu generiert werden können)
CLOBBER.include( 'de/store', 'en/store', 'test/de/store', 'doc' ,'pkg/*' )
CLOBBER.exclude( PACKAGE_PATH )

# => LINGO-FILES
# => Diese Dateien benötigt Lingo um zu funktionieren
LANG_DE = [ 'de.lang', 'de/lingo-*.txt', 'de/user-dic.txt', 'txt/artikel.txt' ]
LANG_EN = [ 'en.lang', 'en/lingo-*.txt', 'en/user-dic.txt', 'txt/artikel-en.txt' ]

LINGO_CORE = [ 'lingo.rb', 'lib/*.rb', 'lib/attendee/*.rb' ]
LINGO_CONF = [ 'lingo.cfg', 'lingo.opt', 'lingo-en.cfg' ]
LINGO_DOCU = [ 'doc/**/*' ]
LINGO_INFO = [ 'info/gpl-hdr.txt', 'info/*.png' ]

TEST_CORE = [ 'test.cfg', 'test/ts_*.rb', 'test/attendee/*.rb' ]
TEST_DATA = [ '??/test_*.txt', 'test/lir*.txt', 'test/mul.txt', 'test/ref/*', 'test/de/*' ]

RELEASE = [ 'README', 'ChangeLog', 'COPYING', 'Rakefile', 'TODO' ]
LIR_FILES = [ 'lir.cfg', 'txt/lir.txt' ]
PORTER_FILES = [ 'porter/*' ]

RUBY_CMD = Config::CONFIG.values_at('RUBY_INSTALL_NAME', 'EXEEXT').join
DEV_NULL = RUBY_PLATFORM =~ /mswin|mingw/ ? 'NUL:' : '/dev/null'


#desc 'Default: proceed to testing lab...'
task :default => :test

################################################################################
#
# => :deploy
#
desc 'Stelle die aktuelle Version auf Subversion bereit'
task :deploy => [ :package, :test_remote ] do
    system( 'svn status' ) || exit
end

################################################################################
#
# => :package
#
task :package => [ :testall, :rdoc ]

desc 'Packettierung von Lingo'
Rake::PackageTask.new( PACKAGE_NAME, LINGO_VERSION ) do |pkg|
    pkg.need_zip = true
    pkg.package_files.include( LINGO_CORE, LINGO_CONF, LINGO_DOCU, LINGO_INFO )
    pkg.package_files.include( LANG_DE, LANG_EN )
    pkg.package_files.include( TEST_CORE, TEST_DATA )
    pkg.package_files.include( RELEASE, LIR_FILES, PORTER_FILES )
end


################################################################################
#
# => :rdoc
#
desc 'Erstellen der Dokumentation'
Rake::RDocTask.new do |doc|
    doc.title = 'Lex Lingo - RDoc Dokumentation'
    doc.options = [ '--charset', 'UTF-8' ]
    doc.rdoc_dir = 'doc'
    doc.rdoc_files.include( 'README', 'ChangeLog', 'TODO', 'lib/attendee/*.rb' )
end


################################################################################
#
# => testall
#
desc 'Vollständiger Test der Lingo-Funktionalität'
task :testall => [ :test, :test_txt, :test_lir ]


################################################################################
#
# => test
#
desc 'Testen des Lingo-Core'
Rake::TestTask.new( :test ) do |tst|
    tst.test_files = FileList.new( 'test/ts_*.rb', 'test/attendee/ts_*.rb' )
end


################################################################################
#
# => test_txt
#
desc 'Vollständiges Testen der Lingo-Prozesse anhand einer Textdatei'
task :test_txt => [] do

    # => Testlauf mit normaler Textdatei
    system( "#{RUBY_CMD} lingo.rb -c test txt/artikel.txt >#{DEV_NULL}" ) or exit 1

    # => Für jede vorhandene _ref-Dateien sollen die Ergebnisse verglichen werden
    continue = 0
    Dir[ 'test/ref/artikel.*' ].each do |ref|
      org = ref.gsub(/test\/ref/, 'txt')
      puts '#' * 60 + "  Teste #{org}"
      continue += Diff::LCS::Ldiff.run(ARGV.clear << org << ref)
    end

    exit 2 unless continue.zero?
end


################################################################################
#
# => test_lir
#
desc 'Vollständiges Testen der Lingo-Prozesse anhand einer LIR-Datei'
task :test_lir => [] do

    # => Testlauf mit LIR-Datei
    system( "#{RUBY_CMD} lingo.rb -c lir txt/lir.txt >#{DEV_NULL}" ) or exit 1

    # => Für jede vorhandene _ref-Dateien sollen die Ergebnisse verglichen werden
    continue = 0
    Dir[ 'test/ref/lir.*' ].each do |ref|
      org = ref.gsub(/test\/ref/, 'txt')
      puts '#' * 60 + "  Teste #{org}"
      continue += Diff::LCS::Ldiff.run(ARGV.clear << org << ref)
    end

    exit 2 unless continue.zero?
end


################################################################################
#
# => test_remote
#
desc 'Vollständiges Testen der fertig packettierten Lingo-Version'
task :test_remote => [ :package ] do

    chdir( PACKAGE_PATH.gsub( /\.zip/, '' ) ) do

        # => Testlauf im Package-Verzeichnis
        system( "rake testall" ) || exit

    end

end




=begin



desc '...starting tests, stand-by...'
task :test => :test_init


def lingo_gpl
  message( "Aktualisiere GPL-Hinweis" )

  #  GPL-Header aller Ruby-Dateien erneuern
  FileUtils.chdir( TST_PATH ) do
    Dir['**/*.rb'].each do |filename|
      rubycode = File.open( filename ).readlines
      lex_idx  = rubycode.rindex( LEX_TEXT )
      code_start = (lex_idx ||= -1) + 1
      rubycode = GPL_TEXT + rubycode[ code_start..-1 ]
      File.open( filename, 'w') do |file|
        file.write( rubycode.join )
      end
    end
  end

end



GPL_TEXT  = File.open( 'info/gpl-hdr.txt' ).readlines
LEX_TEXT  = "#  Lex Lingo rules from here on" + $/


=end
