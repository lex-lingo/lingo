# -*- encoding: utf-8 -*-
# stub: lingo 1.8.7 ruby lib

Gem::Specification.new do |s|
  s.name = "lingo"
  s.version = "1.8.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["John Vorhauer", "Jens Wille"]
  s.date = "2015-08-07"
  s.description = "Lingo is an open source indexing system for research and teachings.\nThe main functions of Lingo are:\n\n* identification of (i.e. reduction to) basic word form by means of\n  dictionaries and suffix lists\n* algorithmic decomposition\n* dictionary-based synonymisation and identification of phrases\n* generic identification of phrases/word sequences based on patterns\n  of word classes\n"
  s.email = ["lingo@vorhauer.de", "jens.wille@gmail.com"]
  s.executables = ["lingo", "lingoctl", "lingosrv", "lingoweb"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["COPYING", "ChangeLog", "README", "Rakefile", "bin/lingo", "bin/lingoctl", "bin/lingosrv", "bin/lingoweb", "config/lingo-call.cfg", "config/lingo.cfg", "config/lir.cfg", "dict/de/lingo-abk.txt", "dict/de/lingo-dic.txt", "dict/de/lingo-mul.txt", "dict/de/lingo-syn.txt", "dict/de/test_dic.txt", "dict/de/test_gen.txt", "dict/de/test_mu2.txt", "dict/de/test_muh.txt", "dict/de/test_mul.txt", "dict/de/test_sgw.txt", "dict/de/test_syn.txt", "dict/de/user-dic.txt", "dict/en/lingo-dic.txt", "dict/en/lingo-irr.txt", "dict/en/lingo-mul.txt", "dict/en/lingo-syn.txt", "dict/en/lingo-wdn.txt", "dict/en/user-dic.txt", "dict/ru/lingo-dic.txt", "dict/ru/lingo-mul.txt", "dict/ru/lingo-syn.txt", "dict/ru/user-dic.txt", "lang/de.lang", "lang/en.lang", "lang/ru.lang", "lib/lingo.rb", "lib/lingo/app.rb", "lib/lingo/attendee.rb", "lib/lingo/attendee/abbreviator.rb", "lib/lingo/attendee/analysis_filter.rb", "lib/lingo/attendee/debug_filter.rb", "lib/lingo/attendee/debugger.rb", "lib/lingo/attendee/decomposer.rb", "lib/lingo/attendee/formatter.rb", "lib/lingo/attendee/hal_filter.rb", "lib/lingo/attendee/lsi_filter.rb", "lib/lingo/attendee/multi_worder.rb", "lib/lingo/attendee/object_filter.rb", "lib/lingo/attendee/sequencer.rb", "lib/lingo/attendee/stemmer.rb", "lib/lingo/attendee/stemmer/porter.rb", "lib/lingo/attendee/synonymer.rb", "lib/lingo/attendee/text_reader.rb", "lib/lingo/attendee/text_writer.rb", "lib/lingo/attendee/tokenizer.rb", "lib/lingo/attendee/variator.rb", "lib/lingo/attendee/vector_filter.rb", "lib/lingo/attendee/word_searcher.rb", "lib/lingo/buffered_attendee.rb", "lib/lingo/call.rb", "lib/lingo/cli.rb", "lib/lingo/config.rb", "lib/lingo/ctl.rb", "lib/lingo/ctl/analysis.rb", "lib/lingo/ctl/files.rb", "lib/lingo/ctl/other.rb", "lib/lingo/database.rb", "lib/lingo/database/crypter.rb", "lib/lingo/database/gdbm_store.rb", "lib/lingo/database/hash_store.rb", "lib/lingo/database/libcdb_store.rb", "lib/lingo/database/progress.rb", "lib/lingo/database/sdbm_store.rb", "lib/lingo/database/source.rb", "lib/lingo/database/source/key_value.rb", "lib/lingo/database/source/multi_key.rb", "lib/lingo/database/source/multi_value.rb", "lib/lingo/database/source/single_word.rb", "lib/lingo/database/source/word_class.rb", "lib/lingo/debug.rb", "lib/lingo/deferred_attendee.rb", "lib/lingo/error.rb", "lib/lingo/language.rb", "lib/lingo/language/char.rb", "lib/lingo/language/dictionary.rb", "lib/lingo/language/grammar.rb", "lib/lingo/language/lexical.rb", "lib/lingo/language/lexical_hash.rb", "lib/lingo/language/token.rb", "lib/lingo/language/word.rb", "lib/lingo/language/word_form.rb", "lib/lingo/progress.rb", "lib/lingo/srv.rb", "lib/lingo/srv/config.ru", "lib/lingo/srv/lingosrv.cfg", "lib/lingo/srv/public/.gitkeep", "lib/lingo/text_utils.rb", "lib/lingo/version.rb", "lib/lingo/web.rb", "lib/lingo/web/config.ru", "lib/lingo/web/lingoweb.cfg", "lib/lingo/web/public/lingo.png", "lib/lingo/web/public/lingoweb.css", "lib/lingo/web/views/index.erb", "test/attendee/ts_abbreviator.rb", "test/attendee/ts_decomposer.rb", "test/attendee/ts_multi_worder.rb", "test/attendee/ts_object_filter.rb", "test/attendee/ts_sequencer.rb", "test/attendee/ts_stemmer.rb", "test/attendee/ts_synonymer.rb", "test/attendee/ts_text_reader.rb", "test/attendee/ts_text_writer.rb", "test/attendee/ts_tokenizer.rb", "test/attendee/ts_variator.rb", "test/attendee/ts_vector_filter.rb", "test/attendee/ts_word_searcher.rb", "test/lir.txt", "test/lir.vec", "test/lir2.txt", "test/lir3.txt", "test/mul.txt", "test/ref/artikel.mul", "test/ref/artikel.non", "test/ref/artikel.seq", "test/ref/artikel.syn", "test/ref/artikel.vec", "test/ref/artikel.vef", "test/ref/artikel.ven", "test/ref/artikel.ver", "test/ref/artikel.vet", "test/ref/lir.mul", "test/ref/lir.non", "test/ref/lir.seq", "test/ref/lir.syn", "test/ref/lir.vec", "test/ref/lir.vef", "test/ref/lir.ven", "test/ref/lir.ver", "test/ref/lir.vet", "test/test_helper.rb", "test/ts_database.rb", "test/ts_language.rb", "txt/artikel-en.txt", "txt/artikel-ru.txt", "txt/artikel.txt", "txt/lir.txt"]
  s.homepage = "http://lex-lingo.de"
  s.licenses = ["AGPL-3.0"]
  s.post_install_message = "\nlingo-1.8.7 [2015-08-07]:\n\n* Added Lingo::Attendee::LsiFilter to correlate semantically related terms\n  (LSI[https://en.wikipedia.org/wiki/Latent_semantic_indexing]) over the\n  \"corpus\" of all files processed during a single program invocation; requires\n  lsi4r[https://blackwinter.github.com/lsi4r] which in turn requires\n  rb-gsl[https://blackwinter.github.com/rb-gsl]. [EXPERIMENTAL: Interface may\n  be changed or removed in next release.]\n* Added Lingo::Attendee::HalFilter to correlate semantically related terms\n  (HAL[https://en.wikipedia.org/wiki/Hyperspace_Analogue_to_Language]) over\n  individual documents; requires hal4r[https://blackwinter.github.com/hal4r]\n  which in turn requires rb-gsl[https://blackwinter.github.com/rb-gsl].\n  [EXPERIMENTAL: Interface may be changed or removed in next release.]\n* Added Lingo::Attendee::AnalysisFilter and associated +lingoctl+ tooling.\n* Multiword dictionaries can now identify hyphenated variants (e.g.\n  <tt>automatic data-processing</tt>); set <tt>hyphenate: true</tt> in the\n  dictionary config.\n* Lingo::Attendee::Tokenizer no longer considers hyphens at word edges as part\n  of the word. As a consequence, Lingo::Attendee::Dehyphenizer has been\n  dropped.\n* Dropped Lingo::Attendee::NonewordFilter; use Lingo::Attendee::VectorFilter\n  with option <tt>lexicals: '\\?'</tt> instead.\n* Lingo::Attendee::TextReader and Lingo::Attendee::TextWriter learned\n  +encoding+ option to read/write text that is not UTF-8 encoded;\n  configuration files and dictionaries still need to be UTF-8, though.\n* Lingo::Attendee::TextReader and Lingo::Attendee::TextWriter learned to\n  read/write Gzip-compressed files (file extension +.gz+ or +.gzip+).\n* Lingo::Attendee::Sequencer learned to recognize +0+ in the pattern to match\n  number tokens.\n* Fixed Lingo::Attendee::TextReader to recognize BOM in input files; does not\n  apply to input read from +STDIN+.\n* Fixed regression introduced in 1.8.6 where Lingo::Attendee::Debugger would\n  no longer work immediately behind Lingo::Attendee::TextReader.\n* Fixed +lingoctl+ copy commands when overwriting existing files.\n* Refactored Lingo::Database::Crypter into a module.\n* JRuby 9000 compatibility.\n\n"
  s.rdoc_options = ["--title", "lingo Application documentation (v1.8.7)", "--charset", "UTF-8", "--line-numbers", "--all", "--main", "README"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.4.8"
  s.summary = "The full-featured automatic indexing system"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cyclops>, ["~> 0.1"])
      s.add_runtime_dependency(%q<nuggets>, ["~> 1.3"])
      s.add_runtime_dependency(%q<rubyzip>, ["~> 1.1"])
      s.add_runtime_dependency(%q<sinatra-bells>, ["~> 0.0"])
      s.add_runtime_dependency(%q<unicode>, ["~> 0.4"])
      s.add_development_dependency(%q<diff-lcs>, ["~> 1.2"])
      s.add_development_dependency(%q<open4>, ["~> 1.3"])
      s.add_development_dependency(%q<hen>, [">= 0.8.2", "~> 0.8"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
    else
      s.add_dependency(%q<cyclops>, ["~> 0.1"])
      s.add_dependency(%q<nuggets>, ["~> 1.3"])
      s.add_dependency(%q<rubyzip>, ["~> 1.1"])
      s.add_dependency(%q<sinatra-bells>, ["~> 0.0"])
      s.add_dependency(%q<unicode>, ["~> 0.4"])
      s.add_dependency(%q<diff-lcs>, ["~> 1.2"])
      s.add_dependency(%q<open4>, ["~> 1.3"])
      s.add_dependency(%q<hen>, [">= 0.8.2", "~> 0.8"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 0"])
    end
  else
    s.add_dependency(%q<cyclops>, ["~> 0.1"])
    s.add_dependency(%q<nuggets>, ["~> 1.3"])
    s.add_dependency(%q<rubyzip>, ["~> 1.1"])
    s.add_dependency(%q<sinatra-bells>, ["~> 0.0"])
    s.add_dependency(%q<unicode>, ["~> 0.4"])
    s.add_dependency(%q<diff-lcs>, ["~> 1.2"])
    s.add_dependency(%q<open4>, ["~> 1.3"])
    s.add_dependency(%q<hen>, [">= 0.8.2", "~> 0.8"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 0"])
  end
end
