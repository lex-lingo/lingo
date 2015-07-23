# encoding: utf-8

require_relative 'lib/lingo/version'

begin
  require 'hen'

  Hen.lay! {{
    gem: {
      name:         'lingo',
      version:      Lingo::VERSION,
      summary:      'The full-featured automatic indexing system',
      authors:      ['John Vorhauer', 'Jens Wille'],
      email:        ['lingo@vorhauer.de', 'jens.wille@gmail.com'],
      license:      'AGPL-3.0',
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
        'lib/lingo/{srv,web}/**/{,.}*',
        'config/*.cfg',
        'dict/*/*.txt',
        'lang/*.lang',
        'txt/*.txt'
      ].to_a,

      dependencies: {
        'cyclops'       => '~> 0.1',
        'nuggets'       => '~> 1.3',
        'rubyzip'       => '~> 1.1',
        'sinatra-bells' => '~> 0.0',
        'unicode'       => '~> 0.4'
      },

      development_dependencies: {
        'diff-lcs' => '~> 1.2',
        'open4'    => '~> 1.3'
      },

      required_ruby_version: '>= 1.9.3'
    },
    test: {
      pattern: %w[test/ts_*.rb test/attendee/ts_*.rb]
    }
  }}
rescue LoadError => err
  warn "Please install the `hen' gem. (#{err})"
end

CLEAN.include(
  'txt/*.{als,log,lsi,mul,non,seq,ste,syn,ve?}',
  'test/{test.*,text.non}',
  'store/*/*.rev'
)

CLOBBER.include('store')

desc 'Run ALL tests'
task 'test:all' => %w[test test:txt test:lir]

desc 'Test against reference file (TXT)'
task('test:txt') { test_ref('artikel', 'lingo') }

desc 'Test against reference file (LIR)'
task('test:lir') { test_ref('lir') }

def test_ref(name, cfg = name)
  require 'diff/lcs'
  require 'diff/lcs/hunk'
  require 'nuggets/ruby'

  jruby = RUBY_ENGINE == 'jruby'
  jruby_lir = jruby && name == 'lir'

  cmd = %W[bin/lingo -c #{cfg} txt/#{name}.txt]
  buf, diff = ["Command failed: #{cmd.join(' ')}"], 0

  Process.ruby(*cmd, I: :lib, &jruby ?
    lambda { |_, _, o, e| buf << e.read; buf << o.read } :
    lambda { |_, _, o, e| IO.interact({}, { o => buf, e => buf }) }
  ).success? or abort buf.join("\n\n")

  Dir["test/ref/#{name}.*"].sort.each { |ref|
    unless File.exist?(txt = ref.sub(/test\/ref/, 'txt'))
      puts "?? #{txt}"
    else
      puts "## #{txt}"

      data = [ref, txt].map { |file|
        File.readlines(file).each { |line|
          line.chomp!
          line.gsub!(/(\d+\.\d+)\d/, '\1') if jruby_lir
        }
      }

      diffs, fld = Diff::LCS.diff(*data), 0

      diffs.empty? ? next : diffs.each { |piece|
        dlh = Diff::LCS::Hunk.new(*data, piece, 0, fld)
        fld = dlh.file_length_difference
        puts dlh.diff(:old)
      }
    end

    diff += 1
  }

  exit diff + 1 unless diff.zero?
end
