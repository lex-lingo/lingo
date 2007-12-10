require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/rdoctask'

PACKAGE_NAME = 'lingo'
LINGO_VERSION = '1.6.6'
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
LANG_DE = FileList.new( 'de.lang', 'de/lingo-*.txt', 'de/user-dic.txt', 'txt/artikel.txt' )
LANG_EN = FileList.new( 'en.lang', 'en/lingo-*.txt', 'en/user-dic.txt', 'txt/artikel-en.txt' )

LINGO_CORE = FileList.new( 'lingo.rb', 'lib/*.rb', 'lib/attendee/*.rb' )
LINGO_CONF = FileList.new( 'lingo.cfg', 'lingo.opt', 'lingo-en.cfg' )
LINGO_DOCU = FileList.new( 'doc/*' )
LINGO_INFO = FileList.new( 'info/gpl-hdr.txt', 'info/*.png' )

TEST_CORE = FileList.new( 'test.cfg', 'test/ts_*.rb', 'test/attendee/*.rb' )
TEST_DATA = FileList.new( '??/test_*.txt', 'test/lir*.txt', 'test/mul.txt', 'test/ref/*', 'test/de/*' )

RELEASE = FileList.new( 'readme', 'release', 'license', 'rakefile.rb' )
LIR_FILES = FileList.new( 'lir.cfg', 'txt/lir.txt' )



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
    pkg.package_files.include( RELEASE, LIR_FILES )
end


################################################################################
#
# => :rdoc
#
desc 'Erstellen der Dokumentation'
Rake::RDocTask.new do |doc|
    doc.title = 'Lex Lingo - RDoc Dokumentation'
    doc.rdoc_dir = 'doc'
    doc.rdoc_files.include( 'release', 'readme', 'lib/attendee/*.rb' )
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
  	system( "ruby lingo.rb -c test txt/artikel.txt" ) || exit

    # => Für jede vorhandene _ref-Dateien sollen die Ergebnisse verglichen werden
    continue = true
		Dir[ 'test/ref/artikel.*' ].each do |ref|
  	  org = ref.gsub(/test\/ref/, 'txt')
		  puts '#' * 60 + "  Teste #{org}"
    	system( "diff -b #{ref} #{org}" ) || (continue = false)
		end

    exit unless continue
end


################################################################################
#
# => test_lir
#
desc 'Vollständiges Testen der Lingo-Prozesse anhand einer LIR-Datei'
task :test_lir => [] do

    # => Testlauf mit LIR-Datei
  	system( "ruby lingo.rb -c lir txt/lir.txt" ) || exit

    # => Für jede vorhandene _ref-Dateien sollen die Ergebnisse verglichen werden
    continue = true
		Dir[ 'test/ref/lir.*' ].each do |ref|
  	  org = ref.gsub(/test\/ref/, 'txt')
		  puts '#' * 60 + "  Teste #{org}"
    	system( "diff -b #{ref} #{org}" ) || (continue = false)
		end

    exit unless continue
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
	
	#	GPL-Header aller Ruby-Dateien erneuern
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



GPL_TEXT	= File.open( 'info/gpl-hdr.txt' ).readlines
LEX_TEXT	= "#  Lex Lingo rules from here on" + $/


=end
