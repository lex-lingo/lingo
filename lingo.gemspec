# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "lingo"
  s.version = "1.8.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Vorhauer", "Jens Wille"]
  s.date = "2012-09-20"
  s.description = "Lingo is an open source indexing system for research and teachings.\nThe main functions of Lingo are:\n\n* identification of (i.e. reduction to) basic word form by means of\n  dictionaries and suffix lists\n* algorithmic decomposition\n* dictionary-based synonymisation and identification of phrases\n* generic identification of phrases/word sequences based on patterns\n  of word classes\n"
  s.email = ["lingo@vorhauer.de", "jens.wille@uni-koeln.de"]
  s.executables = ["lingosrv", "lingo", "lingoctl", "lingoweb"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["lib/lingo/config.rb", "lib/lingo/version.rb", "lib/lingo/cli.rb", "lib/lingo/srv.rb", "lib/lingo/web.rb", "lib/lingo/agenda_item.rb", "lib/lingo/ctl.rb", "lib/lingo/language/lexical_hash.rb", "lib/lingo/language/word.rb", "lib/lingo/language/char.rb", "lib/lingo/language/lexical.rb", "lib/lingo/language/token.rb", "lib/lingo/language/grammar.rb", "lib/lingo/language/dictionary.rb", "lib/lingo/language/word_form.rb", "lib/lingo/error.rb", "lib/lingo/database/source.rb", "lib/lingo/database/source/key_value.rb", "lib/lingo/database/source/multi_value.rb", "lib/lingo/database/source/single_word.rb", "lib/lingo/database/source/word_class.rb", "lib/lingo/database/source/multi_key.rb", "lib/lingo/database/crypter.rb", "lib/lingo/database/sdbm_store.rb", "lib/lingo/database/libcdb_store.rb", "lib/lingo/database/hash_store.rb", "lib/lingo/database/show_progress.rb", "lib/lingo/database/gdbm_store.rb", "lib/lingo/call.rb", "lib/lingo/attendee/abbreviator.rb", "lib/lingo/attendee/text_writer.rb", "lib/lingo/attendee/debugger.rb", "lib/lingo/attendee/dehyphenizer.rb", "lib/lingo/attendee/stemmer/porter.rb", "lib/lingo/attendee/decomposer.rb", "lib/lingo/attendee/multi_worder.rb", "lib/lingo/attendee/tokenizer.rb", "lib/lingo/attendee/word_searcher.rb", "lib/lingo/attendee/variator.rb", "lib/lingo/attendee/noneword_filter.rb", "lib/lingo/attendee/sequencer.rb", "lib/lingo/attendee/object_filter.rb", "lib/lingo/attendee/stemmer.rb", "lib/lingo/attendee/synonymer.rb", "lib/lingo/attendee/text_reader.rb", "lib/lingo/attendee/formatter.rb", "lib/lingo/attendee/vector_filter.rb", "lib/lingo/show_progress.rb", "lib/lingo/database.rb", "lib/lingo/language.rb", "lib/lingo/attendee.rb", "lib/lingo/debug.rb", "lib/lingo/app.rb", "lib/lingo/buffered_attendee.rb", "lib/lingo.rb", "bin/lingosrv", "bin/lingo", "bin/lingoctl", "bin/lingoweb", "lingo.rb", "lingo.cfg", "lingo-call.cfg", "lir.cfg", "de.lang", "en.lang", "ru.lang", "de/lingo-dic.txt", "de/lingo-abk.txt", "de/lingo-mul.txt", "de/lingo-syn.txt", "de/user-dic.txt", "de/test_syn2.txt", "de/test_mul2.txt", "de/test_mul.txt", "de/test_syn.txt", "de/test_dic.txt", "de/test_singleword.txt", "en/lingo-dic.txt", "en/lingo-mul.txt", "en/lingo-wdn.txt", "en/lingo-syn.txt", "en/lingo-irr.txt", "en/user-dic.txt", "ru/lingo-dic.txt", "ru/lingo-mul.txt", "ru/lingo-syn.txt", "txt/artikel.txt", "txt/artikel-en.txt", "txt/artikel-ru.txt", "txt/lir.txt", "lib/lingo/srv/lingosrv.cfg", "lib/lingo/srv/config.ru", "lib/lingo/web/lingoweb.cfg", "lib/lingo/web/public/lingo.png", "lib/lingo/web/public/lingoweb.css", "lib/lingo/web/views/index.erb", "lib/lingo/web/config.ru", "COPYING", "ChangeLog", "Rakefile", "README", "spec/spec_helper.rb", ".rspec", "test/ref/artikel.ven", "test/ref/lir.mul", "test/ref/lir.seq", "test/ref/artikel.mul", "test/ref/lir.syn", "test/ref/artikel.ver", "test/ref/artikel.seq", "test/ref/artikel.non", "test/ref/lir.non", "test/ref/artikel.vec", "test/ref/lir.vec", "test/ref/artikel.syn", "test/lir2.txt", "test/ts_database.rb", "test/test_helper.rb", "test/attendee/ts_object_filter.rb", "test/attendee/ts_vector_filter.rb", "test/attendee/ts_synonymer.rb", "test/attendee/ts_decomposer.rb", "test/attendee/ts_stemmer.rb", "test/attendee/ts_noneword_filter.rb", "test/attendee/ts_text_writer.rb", "test/attendee/ts_sequencer.rb", "test/attendee/ts_tokenizer.rb", "test/attendee/ts_text_reader.rb", "test/attendee/ts_multi_worder.rb", "test/attendee/ts_variator.rb", "test/attendee/ts_abbreviator.rb", "test/attendee/ts_word_searcher.rb", "test/lir.vec", "test/mul.txt", "test/lir.txt", "test/ts_language.rb"]
  s.homepage = "http://lex-lingo.de"
  s.rdoc_options = ["--charset", "UTF-8", "--line-numbers", "--all", "--title", "lingo Application documentation (v1.8.3)", "--main", "README"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.rubygems_version = "1.8.24"
  s.summary = "The full-featured automatic indexing system"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-nuggets>, [">= 0.8.5"])
      s.add_runtime_dependency(%q<unicode>, [">= 0"])
      s.add_runtime_dependency(%q<highline>, [">= 0"])
      s.add_runtime_dependency(%q<sinatra>, [">= 0"])
      s.add_development_dependency(%q<diff-lcs>, [">= 1.1.3"])
      s.add_development_dependency(%q<open4>, [">= 0"])
    else
      s.add_dependency(%q<ruby-nuggets>, [">= 0.8.5"])
      s.add_dependency(%q<unicode>, [">= 0"])
      s.add_dependency(%q<highline>, [">= 0"])
      s.add_dependency(%q<sinatra>, [">= 0"])
      s.add_dependency(%q<diff-lcs>, [">= 1.1.3"])
      s.add_dependency(%q<open4>, [">= 0"])
    end
  else
    s.add_dependency(%q<ruby-nuggets>, [">= 0.8.5"])
    s.add_dependency(%q<unicode>, [">= 0"])
    s.add_dependency(%q<highline>, [">= 0"])
    s.add_dependency(%q<sinatra>, [">= 0"])
    s.add_dependency(%q<diff-lcs>, [">= 1.1.3"])
    s.add_dependency(%q<open4>, [">= 0"])
  end
end
