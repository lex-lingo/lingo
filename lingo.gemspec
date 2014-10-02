# -*- encoding: utf-8 -*-
# stub: lingo 1.8.5 ruby lib

Gem::Specification.new do |s|
  s.name = "lingo"
  s.version = "1.8.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["John Vorhauer", "Jens Wille"]
  s.date = "2014-10-02"
  s.description = "Lingo is an open source indexing system for research and teachings.\nThe main functions of Lingo are:\n\n* identification of (i.e. reduction to) basic word form by means of\n  dictionaries and suffix lists\n* algorithmic decomposition\n* dictionary-based synonymisation and identification of phrases\n* generic identification of phrases/word sequences based on patterns\n  of word classes\n"
  s.email = ["lingo@vorhauer.de", "jens.wille@gmail.com"]
  s.executables = ["lingo", "lingoctl", "lingosrv", "lingoweb"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["COPYING", "ChangeLog", "README", "Rakefile", "bin/lingo", "bin/lingoctl", "bin/lingosrv", "bin/lingoweb", "de.lang", "de/lingo-abk.txt", "de/lingo-dic.txt", "de/lingo-mul.txt", "de/lingo-syn.txt", "de/test_dic.txt", "de/test_gen.txt", "de/test_mu2.txt", "de/test_mul.txt", "de/test_sgw.txt", "de/test_syn.txt", "de/user-dic.txt", "en.lang", "en/lingo-dic.txt", "en/lingo-irr.txt", "en/lingo-mul.txt", "en/lingo-syn.txt", "en/lingo-wdn.txt", "en/user-dic.txt", "lib/lingo.rb", "lib/lingo/agenda_item.rb", "lib/lingo/app.rb", "lib/lingo/attendee.rb", "lib/lingo/attendee/abbreviator.rb", "lib/lingo/attendee/debugger.rb", "lib/lingo/attendee/decomposer.rb", "lib/lingo/attendee/dehyphenizer.rb", "lib/lingo/attendee/formatter.rb", "lib/lingo/attendee/multi_worder.rb", "lib/lingo/attendee/noneword_filter.rb", "lib/lingo/attendee/object_filter.rb", "lib/lingo/attendee/sequencer.rb", "lib/lingo/attendee/stemmer.rb", "lib/lingo/attendee/stemmer/porter.rb", "lib/lingo/attendee/synonymer.rb", "lib/lingo/attendee/text_reader.rb", "lib/lingo/attendee/text_writer.rb", "lib/lingo/attendee/tokenizer.rb", "lib/lingo/attendee/variator.rb", "lib/lingo/attendee/vector_filter.rb", "lib/lingo/attendee/word_searcher.rb", "lib/lingo/buffered_attendee.rb", "lib/lingo/call.rb", "lib/lingo/cli.rb", "lib/lingo/config.rb", "lib/lingo/ctl.rb", "lib/lingo/database.rb", "lib/lingo/database/crypter.rb", "lib/lingo/database/gdbm_store.rb", "lib/lingo/database/hash_store.rb", "lib/lingo/database/libcdb_store.rb", "lib/lingo/database/progress.rb", "lib/lingo/database/sdbm_store.rb", "lib/lingo/database/source.rb", "lib/lingo/database/source/key_value.rb", "lib/lingo/database/source/multi_key.rb", "lib/lingo/database/source/multi_value.rb", "lib/lingo/database/source/single_word.rb", "lib/lingo/database/source/word_class.rb", "lib/lingo/debug.rb", "lib/lingo/error.rb", "lib/lingo/language.rb", "lib/lingo/language/char.rb", "lib/lingo/language/dictionary.rb", "lib/lingo/language/grammar.rb", "lib/lingo/language/lexical.rb", "lib/lingo/language/lexical_hash.rb", "lib/lingo/language/token.rb", "lib/lingo/language/word.rb", "lib/lingo/language/word_form.rb", "lib/lingo/progress.rb", "lib/lingo/srv.rb", "lib/lingo/srv/config.ru", "lib/lingo/srv/lingosrv.cfg", "lib/lingo/srv/public/.gitkeep", "lib/lingo/version.rb", "lib/lingo/web.rb", "lib/lingo/web/config.ru", "lib/lingo/web/lingoweb.cfg", "lib/lingo/web/public/lingo.png", "lib/lingo/web/public/lingoweb.css", "lib/lingo/web/views/index.erb", "lingo-call.cfg", "lingo.cfg", "lingo.rb", "lir.cfg", "ru.lang", "ru/lingo-dic.txt", "ru/lingo-mul.txt", "ru/lingo-syn.txt", "ru/user-dic.txt", "spec/spec_helper.rb", "test/attendee/ts_abbreviator.rb", "test/attendee/ts_decomposer.rb", "test/attendee/ts_multi_worder.rb", "test/attendee/ts_noneword_filter.rb", "test/attendee/ts_object_filter.rb", "test/attendee/ts_sequencer.rb", "test/attendee/ts_stemmer.rb", "test/attendee/ts_synonymer.rb", "test/attendee/ts_text_reader.rb", "test/attendee/ts_text_writer.rb", "test/attendee/ts_tokenizer.rb", "test/attendee/ts_variator.rb", "test/attendee/ts_vector_filter.rb", "test/attendee/ts_word_searcher.rb", "test/lir.txt", "test/lir.vec", "test/lir2.txt", "test/mul.txt", "test/ref/artikel.mul", "test/ref/artikel.non", "test/ref/artikel.seq", "test/ref/artikel.syn", "test/ref/artikel.vec", "test/ref/artikel.ven", "test/ref/artikel.ver", "test/ref/lir.mul", "test/ref/lir.non", "test/ref/lir.seq", "test/ref/lir.syn", "test/ref/lir.vec", "test/test_helper.rb", "test/ts_database.rb", "test/ts_language.rb", "txt/artikel-en.txt", "txt/artikel-ru.txt", "txt/artikel.txt", "txt/lir.txt"]
  s.homepage = "http://lex-lingo.de"
  s.licenses = ["AGPL-3.0"]
  s.post_install_message = "\nlingo-1.8.5 [2014-10-02]:\n\n* Dictionary values (projections) are no longer sorted; hence, order of\n  definition affects processing.\n* Lexicals in Lingo::Language::Word are no longer sorted; in particular,\n  compound parts keep their original order.\n* Lexicals in Lingo::Language::Word are no longer cleaned from duplicates.\n* Compiled dictionaries are updated whenever the Lingo version or their\n  configuration changes, not only when the source file's size or modification\n  time changes.\n* Lingo::Attendee::Synonymer learned <tt>compound-parts</tt> option to also\n  generate synonyms for compound parts when set to +true+.\n* Lingo::Attendee::TextReader learned better PDF-to-text conversion using the\n  +pdftotext+ command; specify <tt>filter: pdftotext</tt> in the config.\n* Lingo::Attendee::VectorFilter learned +dict+ option to print words in\n  dictionary format (viz. Lingo::Database::Source::WordClass).\n* Lingo::Attendee::VectorFilter learned +preamble+ option to print current\n  configuration to the beginning of the log file (<tt>debug: 'true'</tt>);\n  set <tt>preamble: false</tt> to disable.\n* Multiword dictionaries compiled from base forms can now generate inflected\n  adjectives based on the gender of the head noun; set <tt>inflect: true</tt>\n  in the dictionary config.\n* Lingo::Database::Source::WordClass supports gender information being encoded\n  in the dictionary as well as shorthand notation for multiple word\n  classes/genders.\n* Lingo::Database::Source::WordClass supports compounds being encoded in the\n  dictionary (appending <tt>+</tt> to their parts' word classes is\n  recommended).\n* Lingo::Database::Source removes leading and trailing whitespace from\n  dictionary lines.\n* Lingo::Database::Crypter uses OpenSSL to encrypt/decrypt dictionaries.\n  Note: Can't decrypt dictionaries encrypted with the old scheme anymore.\n* Lingo::Attendee::Tokenizer learned subset of MediaWiki syntax.\n* Eliminated pathological behaviour of the +URLS+ rule in\n  Lingo::Attendee::Tokenizer.\n* Fixed regression introduced in 1.8.2 where <tt>combine: all</tt> would no\n  longer work in Lingo::Attendee::MultiWorder.\n* Updated and extended Russian dictionaries. (Yulia Dorokhova, Thomas M\u{fc}ller)\n* +lingoctl+ no longer overwrites existing files without confirmation.\n* +lingoctl+ learned +archive+ command.\n* Dictionary cleanup.\n\n"
  s.rdoc_options = ["--title", "lingo Application documentation (v1.8.5)", "--charset", "UTF-8", "--line-numbers", "--all", "--main", "README"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.4.2"
  s.summary = "The full-featured automatic indexing system"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cyclops>, [">= 0.0.4", "~> 0.0"])
      s.add_runtime_dependency(%q<nuggets>, ["~> 1.0"])
      s.add_runtime_dependency(%q<rubyzip>, ["~> 1.1"])
      s.add_runtime_dependency(%q<sinatra-bells>, ["~> 0.0"])
      s.add_runtime_dependency(%q<unicode>, ["~> 0.4"])
      s.add_development_dependency(%q<diff-lcs>, ["~> 1.2"])
      s.add_development_dependency(%q<open4>, ["~> 1.3"])
      s.add_development_dependency(%q<hen>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<cyclops>, [">= 0.0.4", "~> 0.0"])
      s.add_dependency(%q<nuggets>, ["~> 1.0"])
      s.add_dependency(%q<rubyzip>, ["~> 1.1"])
      s.add_dependency(%q<sinatra-bells>, ["~> 0.0"])
      s.add_dependency(%q<unicode>, ["~> 0.4"])
      s.add_dependency(%q<diff-lcs>, ["~> 1.2"])
      s.add_dependency(%q<open4>, ["~> 1.3"])
      s.add_dependency(%q<hen>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<cyclops>, [">= 0.0.4", "~> 0.0"])
    s.add_dependency(%q<nuggets>, ["~> 1.0"])
    s.add_dependency(%q<rubyzip>, ["~> 1.1"])
    s.add_dependency(%q<sinatra-bells>, ["~> 0.0"])
    s.add_dependency(%q<unicode>, ["~> 0.4"])
    s.add_dependency(%q<diff-lcs>, ["~> 1.2"])
    s.add_dependency(%q<open4>, ["~> 1.3"])
    s.add_dependency(%q<hen>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
