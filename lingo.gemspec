# -*- encoding: utf-8 -*-
# stub: lingo 1.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "lingo".freeze
  s.version = "1.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Vorhauer".freeze, "Jens Wille".freeze]
  s.date = "2016-09-13"
  s.description = "Lingo is an open source indexing system for research and teachings.\nThe main functions of Lingo are:\n\n* identification of (i.e. reduction to) basic word form by means of\n  dictionaries and suffix lists\n* algorithmic decomposition\n* dictionary-based synonymisation and identification of phrases\n* generic identification of phrases/word sequences based on patterns\n  of word classes\n".freeze
  s.email = ["lingo@vorhauer.de".freeze, "jens.wille@gmail.com".freeze]
  s.executables = ["lingo".freeze, "lingoctl".freeze, "lingosrv".freeze, "lingoweb".freeze]
  s.extra_rdoc_files = ["README".freeze, "COPYING".freeze, "ChangeLog".freeze]
  s.files = ["COPYING".freeze, "ChangeLog".freeze, "README".freeze, "Rakefile".freeze, "bin/lingo".freeze, "bin/lingoctl".freeze, "bin/lingosrv".freeze, "bin/lingoweb".freeze, "config/lingo-call.cfg".freeze, "config/lingo.cfg".freeze, "config/lir.cfg".freeze, "dict/de/lingo-abk.txt".freeze, "dict/de/lingo-dic.txt".freeze, "dict/de/lingo-mul.txt".freeze, "dict/de/lingo-syn.txt".freeze, "dict/de/test_dic.txt".freeze, "dict/de/test_gen.txt".freeze, "dict/de/test_mu2.txt".freeze, "dict/de/test_muh.txt".freeze, "dict/de/test_mul.txt".freeze, "dict/de/test_sgw.txt".freeze, "dict/de/test_syn.txt".freeze, "dict/de/user-dic.txt".freeze, "dict/en/lingo-dic.txt".freeze, "dict/en/lingo-irr.txt".freeze, "dict/en/lingo-mul.txt".freeze, "dict/en/lingo-syn.txt".freeze, "dict/en/lingo-wdn.txt".freeze, "dict/en/user-dic.txt".freeze, "dict/ru/lingo-dic.txt".freeze, "dict/ru/lingo-mul.txt".freeze, "dict/ru/lingo-syn.txt".freeze, "dict/ru/user-dic.txt".freeze, "lang/de.lang".freeze, "lang/en.lang".freeze, "lang/ru.lang".freeze, "lib/lingo.rb".freeze, "lib/lingo/app.rb".freeze, "lib/lingo/array_utils.rb".freeze, "lib/lingo/attendee.rb".freeze, "lib/lingo/attendee/abbreviator.rb".freeze, "lib/lingo/attendee/analysis_filter.rb".freeze, "lib/lingo/attendee/debug_filter.rb".freeze, "lib/lingo/attendee/debugger.rb".freeze, "lib/lingo/attendee/decomposer.rb".freeze, "lib/lingo/attendee/formatter.rb".freeze, "lib/lingo/attendee/hal_filter.rb".freeze, "lib/lingo/attendee/lsi_filter.rb".freeze, "lib/lingo/attendee/multi_worder.rb".freeze, "lib/lingo/attendee/object_filter.rb".freeze, "lib/lingo/attendee/sequencer.rb".freeze, "lib/lingo/attendee/stemmer.rb".freeze, "lib/lingo/attendee/stemmer/porter.rb".freeze, "lib/lingo/attendee/synonymer.rb".freeze, "lib/lingo/attendee/text_reader.rb".freeze, "lib/lingo/attendee/text_writer.rb".freeze, "lib/lingo/attendee/tokenizer.rb".freeze, "lib/lingo/attendee/variator.rb".freeze, "lib/lingo/attendee/vector_filter.rb".freeze, "lib/lingo/attendee/word_searcher.rb".freeze, "lib/lingo/buffered_attendee.rb".freeze, "lib/lingo/call.rb".freeze, "lib/lingo/cli.rb".freeze, "lib/lingo/config.rb".freeze, "lib/lingo/ctl.rb".freeze, "lib/lingo/ctl/analysis.rb".freeze, "lib/lingo/ctl/files.rb".freeze, "lib/lingo/ctl/other.rb".freeze, "lib/lingo/database.rb".freeze, "lib/lingo/database/crypter.rb".freeze, "lib/lingo/database/gdbm_store.rb".freeze, "lib/lingo/database/hash_store.rb".freeze, "lib/lingo/database/libcdb_store.rb".freeze, "lib/lingo/database/progress.rb".freeze, "lib/lingo/database/sdbm_store.rb".freeze, "lib/lingo/database/source.rb".freeze, "lib/lingo/database/source/key_value.rb".freeze, "lib/lingo/database/source/multi_key.rb".freeze, "lib/lingo/database/source/multi_value.rb".freeze, "lib/lingo/database/source/single_word.rb".freeze, "lib/lingo/database/source/word_class.rb".freeze, "lib/lingo/debug.rb".freeze, "lib/lingo/deferred_attendee.rb".freeze, "lib/lingo/error.rb".freeze, "lib/lingo/filter.rb".freeze, "lib/lingo/filter/pdf.rb".freeze, "lib/lingo/filter/xml.rb".freeze, "lib/lingo/language.rb".freeze, "lib/lingo/language/char.rb".freeze, "lib/lingo/language/dictionary.rb".freeze, "lib/lingo/language/grammar.rb".freeze, "lib/lingo/language/lexical.rb".freeze, "lib/lingo/language/lexical_hash.rb".freeze, "lib/lingo/language/token.rb".freeze, "lib/lingo/language/word.rb".freeze, "lib/lingo/language/word_form.rb".freeze, "lib/lingo/progress.rb".freeze, "lib/lingo/srv.rb".freeze, "lib/lingo/srv/config.ru".freeze, "lib/lingo/srv/lingosrv.cfg".freeze, "lib/lingo/srv/public/.gitkeep".freeze, "lib/lingo/text_utils.rb".freeze, "lib/lingo/version.rb".freeze, "lib/lingo/web.rb".freeze, "lib/lingo/web/config.ru".freeze, "lib/lingo/web/lingoweb.cfg".freeze, "lib/lingo/web/public/lingo.png".freeze, "lib/lingo/web/public/lingoweb.css".freeze, "lib/lingo/web/views/index.erb".freeze, "test/article.html".freeze, "test/article.pdf".freeze, "test/article.txt".freeze, "test/article.xml".freeze, "test/attendee/ts_abbreviator.rb".freeze, "test/attendee/ts_decomposer.rb".freeze, "test/attendee/ts_multi_worder.rb".freeze, "test/attendee/ts_object_filter.rb".freeze, "test/attendee/ts_sequencer.rb".freeze, "test/attendee/ts_stemmer.rb".freeze, "test/attendee/ts_synonymer.rb".freeze, "test/attendee/ts_text_reader.rb".freeze, "test/attendee/ts_text_writer.rb".freeze, "test/attendee/ts_tokenizer.rb".freeze, "test/attendee/ts_variator.rb".freeze, "test/attendee/ts_vector_filter.rb".freeze, "test/attendee/ts_word_searcher.rb".freeze, "test/lir.txt".freeze, "test/lir.vec".freeze, "test/lir2.txt".freeze, "test/lir3.txt".freeze, "test/mul.txt".freeze, "test/ref/artikel.mul".freeze, "test/ref/artikel.non".freeze, "test/ref/artikel.seq".freeze, "test/ref/artikel.syn".freeze, "test/ref/artikel.vec".freeze, "test/ref/artikel.vef".freeze, "test/ref/artikel.ven".freeze, "test/ref/artikel.ver".freeze, "test/ref/artikel.vet".freeze, "test/ref/lir.mul".freeze, "test/ref/lir.non".freeze, "test/ref/lir.seq".freeze, "test/ref/lir.syn".freeze, "test/ref/lir.vec".freeze, "test/ref/lir.vef".freeze, "test/ref/lir.ven".freeze, "test/ref/lir.ver".freeze, "test/ref/lir.vet".freeze, "test/test_helper.rb".freeze, "test/ts_database.rb".freeze, "test/ts_language.rb".freeze, "txt/artikel-en.txt".freeze, "txt/artikel-ru.txt".freeze, "txt/artikel.txt".freeze, "txt/lir.txt".freeze]
  s.homepage = "http://lex-lingo.de".freeze
  s.licenses = ["AGPL-3.0".freeze]
  s.post_install_message = "\nlingo-1.9.0 [2016-09-13]:\n\n* <b>Dropped support for Ruby 1.9.</b>\n* Removed support for deprecated options and attendee names (+old+ \u{2192} +new+):\n  * Lingo::Language::Grammar<b></b>:\n    +compositum+ \u{2192} +compound+\n  * Lingo::Attendee::TextReader<b></b>:\n    +lir-record-pattern+ \u{2192} +records+\n  * Lingo::Config<b></b>:\n    +multiworder+ \u{2192} +multi_worder+,\n    +objectfilter+ \u{2192} +object_filter+,\n    +textreader+ \u{2192} +text_reader+,\n    +textwriter+ \u{2192} +text_writer+,\n    +vectorfilter+ \u{2192} +vector_filter+,\n    +wordsearcher+ \u{2192} +word_searcher+\n* Lingo::Attendee::TextWriter learned format directives for +ext+ option\n  (currently supported are: <tt>%c</tt> = config name, <tt>%l</tt> = language\n  name, <tt>%d</tt> = current date, <tt>%t</tt> = current time).\n* Lingo::Attendee::Sequencer remembers word form of sequences.\n* Updated and extended English system dictionary and suffix list.\n* Fixed errors with XML input (issue #15 by Thomas Berger).\n\n".freeze
  s.rdoc_options = ["--title".freeze, "lingo Application documentation (v1.9.0)".freeze, "--charset".freeze, "UTF-8".freeze, "--line-numbers".freeze, "--all".freeze, "--main".freeze, "README".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "2.6.6".freeze
  s.summary = "The full-featured automatic indexing system".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cyclops>.freeze, ["~> 0.2"])
      s.add_runtime_dependency(%q<nuggets>.freeze, ["~> 1.5"])
      s.add_runtime_dependency(%q<rubyzip>.freeze, ["~> 1.2"])
      s.add_runtime_dependency(%q<sinatra-bells>.freeze, ["~> 0.4"])
      s.add_runtime_dependency(%q<unicode>.freeze, ["~> 0.4"])
      s.add_development_dependency(%q<diff-lcs>.freeze, ["~> 1.2"])
      s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
      s.add_development_dependency(%q<open4>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<pdf-reader>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<hen>.freeze, [">= 0.8.5", "~> 0.8"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
    else
      s.add_dependency(%q<cyclops>.freeze, ["~> 0.2"])
      s.add_dependency(%q<nuggets>.freeze, ["~> 1.5"])
      s.add_dependency(%q<rubyzip>.freeze, ["~> 1.2"])
      s.add_dependency(%q<sinatra-bells>.freeze, ["~> 0.4"])
      s.add_dependency(%q<unicode>.freeze, ["~> 0.4"])
      s.add_dependency(%q<diff-lcs>.freeze, ["~> 1.2"])
      s.add_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
      s.add_dependency(%q<open4>.freeze, ["~> 1.3"])
      s.add_dependency(%q<pdf-reader>.freeze, ["~> 1.4"])
      s.add_dependency(%q<hen>.freeze, [">= 0.8.5", "~> 0.8"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<cyclops>.freeze, ["~> 0.2"])
    s.add_dependency(%q<nuggets>.freeze, ["~> 1.5"])
    s.add_dependency(%q<rubyzip>.freeze, ["~> 1.2"])
    s.add_dependency(%q<sinatra-bells>.freeze, ["~> 0.4"])
    s.add_dependency(%q<unicode>.freeze, ["~> 0.4"])
    s.add_dependency(%q<diff-lcs>.freeze, ["~> 1.2"])
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
    s.add_dependency(%q<open4>.freeze, ["~> 1.3"])
    s.add_dependency(%q<pdf-reader>.freeze, ["~> 1.4"])
    s.add_dependency(%q<hen>.freeze, [">= 0.8.5", "~> 0.8"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end
