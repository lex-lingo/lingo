# -*- encoding: utf-8 -*-
# stub: lingo 1.8.6 ruby lib

Gem::Specification.new do |s|
  s.name = "lingo"
  s.version = "1.8.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["John Vorhauer", "Jens Wille"]
  s.date = "2015-02-09"
  s.description = "Lingo is an open source indexing system for research and teachings.\nThe main functions of Lingo are:\n\n* identification of (i.e. reduction to) basic word form by means of\n  dictionaries and suffix lists\n* algorithmic decomposition\n* dictionary-based synonymisation and identification of phrases\n* generic identification of phrases/word sequences based on patterns\n  of word classes\n"
  s.email = ["lingo@vorhauer.de", "jens.wille@gmail.com"]
  s.executables = ["lingo", "lingoctl", "lingosrv", "lingoweb"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["COPYING", "ChangeLog", "README", "Rakefile", "bin/lingo", "bin/lingoctl", "bin/lingosrv", "bin/lingoweb", "config/lingo-call.cfg", "config/lingo.cfg", "config/lir.cfg", "dict/de/lingo-abk.txt", "dict/de/lingo-dic.txt", "dict/de/lingo-mul.txt", "dict/de/lingo-syn.txt", "dict/de/test_dic.txt", "dict/de/test_gen.txt", "dict/de/test_mu2.txt", "dict/de/test_mul.txt", "dict/de/test_sgw.txt", "dict/de/test_syn.txt", "dict/de/user-dic.txt", "dict/en/lingo-dic.txt", "dict/en/lingo-irr.txt", "dict/en/lingo-mul.txt", "dict/en/lingo-syn.txt", "dict/en/lingo-wdn.txt", "dict/en/user-dic.txt", "dict/ru/lingo-dic.txt", "dict/ru/lingo-mul.txt", "dict/ru/lingo-syn.txt", "dict/ru/user-dic.txt", "lang/de.lang", "lang/en.lang", "lang/ru.lang", "lib/lingo.rb", "lib/lingo/app.rb", "lib/lingo/attendee.rb", "lib/lingo/attendee/abbreviator.rb", "lib/lingo/attendee/debugger.rb", "lib/lingo/attendee/decomposer.rb", "lib/lingo/attendee/dehyphenizer.rb", "lib/lingo/attendee/formatter.rb", "lib/lingo/attendee/multi_worder.rb", "lib/lingo/attendee/noneword_filter.rb", "lib/lingo/attendee/object_filter.rb", "lib/lingo/attendee/sequencer.rb", "lib/lingo/attendee/stemmer.rb", "lib/lingo/attendee/stemmer/porter.rb", "lib/lingo/attendee/synonymer.rb", "lib/lingo/attendee/text_reader.rb", "lib/lingo/attendee/text_writer.rb", "lib/lingo/attendee/tokenizer.rb", "lib/lingo/attendee/variator.rb", "lib/lingo/attendee/vector_filter.rb", "lib/lingo/attendee/word_searcher.rb", "lib/lingo/buffered_attendee.rb", "lib/lingo/call.rb", "lib/lingo/cli.rb", "lib/lingo/config.rb", "lib/lingo/ctl.rb", "lib/lingo/database.rb", "lib/lingo/database/crypter.rb", "lib/lingo/database/gdbm_store.rb", "lib/lingo/database/hash_store.rb", "lib/lingo/database/libcdb_store.rb", "lib/lingo/database/progress.rb", "lib/lingo/database/sdbm_store.rb", "lib/lingo/database/source.rb", "lib/lingo/database/source/key_value.rb", "lib/lingo/database/source/multi_key.rb", "lib/lingo/database/source/multi_value.rb", "lib/lingo/database/source/single_word.rb", "lib/lingo/database/source/word_class.rb", "lib/lingo/debug.rb", "lib/lingo/deferred_attendee.rb", "lib/lingo/error.rb", "lib/lingo/language.rb", "lib/lingo/language/char.rb", "lib/lingo/language/dictionary.rb", "lib/lingo/language/grammar.rb", "lib/lingo/language/lexical.rb", "lib/lingo/language/lexical_hash.rb", "lib/lingo/language/token.rb", "lib/lingo/language/word.rb", "lib/lingo/language/word_form.rb", "lib/lingo/progress.rb", "lib/lingo/srv.rb", "lib/lingo/srv/config.ru", "lib/lingo/srv/lingosrv.cfg", "lib/lingo/srv/public/.gitkeep", "lib/lingo/version.rb", "lib/lingo/web.rb", "lib/lingo/web/config.ru", "lib/lingo/web/lingoweb.cfg", "lib/lingo/web/public/lingo.png", "lib/lingo/web/public/lingoweb.css", "lib/lingo/web/views/index.erb", "test/attendee/ts_abbreviator.rb", "test/attendee/ts_decomposer.rb", "test/attendee/ts_multi_worder.rb", "test/attendee/ts_noneword_filter.rb", "test/attendee/ts_object_filter.rb", "test/attendee/ts_sequencer.rb", "test/attendee/ts_stemmer.rb", "test/attendee/ts_synonymer.rb", "test/attendee/ts_text_reader.rb", "test/attendee/ts_text_writer.rb", "test/attendee/ts_tokenizer.rb", "test/attendee/ts_variator.rb", "test/attendee/ts_vector_filter.rb", "test/attendee/ts_word_searcher.rb", "test/lir.txt", "test/lir.vec", "test/lir2.txt", "test/mul.txt", "test/ref/artikel.mul", "test/ref/artikel.non", "test/ref/artikel.seq", "test/ref/artikel.syn", "test/ref/artikel.vec", "test/ref/artikel.vef", "test/ref/artikel.ven", "test/ref/artikel.ver", "test/ref/artikel.vet", "test/ref/lir.mul", "test/ref/lir.non", "test/ref/lir.seq", "test/ref/lir.syn", "test/ref/lir.vec", "test/ref/lir.vef", "test/ref/lir.ven", "test/ref/lir.ver", "test/ref/lir.vet", "test/test_helper.rb", "test/ts_database.rb", "test/ts_language.rb", "txt/artikel-en.txt", "txt/artikel-ru.txt", "txt/artikel.txt", "txt/lir.txt"]
  s.homepage = "http://lex-lingo.de"
  s.licenses = ["AGPL-3.0"]
  s.post_install_message = "\nlingo-1.8.6 [2015-02-09]:\n\n* Lingo::Attendee::VectorFilter learned +pos+ option to print position and\n  byte offset with each word.\n* Lingo::Attendee::VectorFilter learned +tfidf+ option to sort results based\n  on their tf\u{2013}idf[https://en.wikipedia.org/wiki/Tf\u{2013}idf] score; the document\n  frequencies are calculated over the \"corpus\" of all files processed during\n  a single program invocation.\n* Lingo::Attendee::VectorFilter learned +tokens+ option to filter on\n  Lingo::Language::Token in addition to Lingo::Language::Word.\n* Lingo::Attendee::VectorFilter no longer supports +debug+ (as well as\n  +prompt+ and +preamble+); use Lingo::Attendee::DebugFilter instead.\n* Lingo::Attendee::TextReader no longer removes line endings; option +chomp+\n  is obsolete.\n* Lingo::Attendee::TextReader passes byte offset to the following attendee.\n* Lingo::Attendee::Tokenizer records token's byte offset.\n* Lingo::Attendee::Tokenizer records token's sequence position.\n* Lingo::Attendee::Tokenizer learned <tt>skip-tags</tt> option to skip over\n  specified tags' contents.\n* Lingo::Attendee subclasses warn when invalid or obsolete options or names\n  are used.\n* Changed German infix substitution +/en+ to +ch/chen+ in order to prevent\n  overly aggressive identifications.\n* Internal refactoring and API changes.\n\n"
  s.rdoc_options = ["--title", "lingo Application documentation (v1.8.6)", "--charset", "UTF-8", "--line-numbers", "--all", "--main", "README"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.4.5"
  s.summary = "The full-featured automatic indexing system"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cyclops>, ["~> 0.1"])
      s.add_runtime_dependency(%q<nuggets>, ["~> 1.1"])
      s.add_runtime_dependency(%q<rubyzip>, ["~> 1.1"])
      s.add_runtime_dependency(%q<sinatra-bells>, ["~> 0.0"])
      s.add_runtime_dependency(%q<unicode>, ["~> 0.4"])
      s.add_development_dependency(%q<diff-lcs>, ["~> 1.2"])
      s.add_development_dependency(%q<open4>, ["~> 1.3"])
      s.add_development_dependency(%q<hen>, [">= 0.8.1", "~> 0.8"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
    else
      s.add_dependency(%q<cyclops>, ["~> 0.1"])
      s.add_dependency(%q<nuggets>, ["~> 1.1"])
      s.add_dependency(%q<rubyzip>, ["~> 1.1"])
      s.add_dependency(%q<sinatra-bells>, ["~> 0.0"])
      s.add_dependency(%q<unicode>, ["~> 0.4"])
      s.add_dependency(%q<diff-lcs>, ["~> 1.2"])
      s.add_dependency(%q<open4>, ["~> 1.3"])
      s.add_dependency(%q<hen>, [">= 0.8.1", "~> 0.8"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 0"])
    end
  else
    s.add_dependency(%q<cyclops>, ["~> 0.1"])
    s.add_dependency(%q<nuggets>, ["~> 1.1"])
    s.add_dependency(%q<rubyzip>, ["~> 1.1"])
    s.add_dependency(%q<sinatra-bells>, ["~> 0.0"])
    s.add_dependency(%q<unicode>, ["~> 0.4"])
    s.add_dependency(%q<diff-lcs>, ["~> 1.2"])
    s.add_dependency(%q<open4>, ["~> 1.3"])
    s.add_dependency(%q<hen>, [">= 0.8.1", "~> 0.8"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 0"])
  end
end
