# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "lingo"
  s.version = "1.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Vorhauer", "Jens Wille"]
  s.date = "2012-01-01"
  s.description = "The full-featured automatic indexing system"
  s.email = ["lingo@vorhauer.de", "jens.wille@uni-koeln.de"]
  s.executables = ["lingo", "lingoctl"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["lib/lingo/attendees.rb", "lib/lingo/ctl.rb", "lib/lingo/database.rb", "lib/lingo/types.rb", "lib/lingo/version.rb", "lib/lingo/utilities.rb", "lib/lingo/cli.rb", "lib/lingo/attendee/variator.rb", "lib/lingo/attendee/debugger.rb", "lib/lingo/attendee/synonymer.rb", "lib/lingo/attendee/wordsearcher.rb", "lib/lingo/attendee/dehyphenizer.rb", "lib/lingo/attendee/multiworder.rb", "lib/lingo/attendee/tokenizer.rb", "lib/lingo/attendee/abbreviator.rb", "lib/lingo/attendee/textwriter.rb", "lib/lingo/attendee/objectfilter.rb", "lib/lingo/attendee/noneword_filter.rb", "lib/lingo/attendee/sequencer.rb", "lib/lingo/attendee/textreader.rb", "lib/lingo/attendee/decomposer.rb", "lib/lingo/attendee/vector_filter.rb", "lib/lingo/config.rb", "lib/lingo/const.rb", "lib/lingo/modules.rb", "lib/lingo/language.rb", "lib/lingo.rb", "bin/lingo", "bin/lingoctl", "lingo.rb", "lingo.cfg", "lingo-all.cfg", "lingo-call.cfg", "de.lang", "en.lang", "de/lingo-syn.txt", "de/lingo-abk.txt", "de/lingo-dic.txt", "de/lingo-mul.txt", "de/user-dic.txt", "en/lingo-dic.txt", "en/lingo-mul.txt", "en/user-dic.txt", "txt/artikel.txt", "txt/artikel-en.txt", "info/gpl-hdr.txt", "info/kerze.png", "info/meeting.png", "info/lingo.png", "info/types.png", "info/logo.png", "info/language.png", "info/Typen.png", "info/Objekte.png", "info/download.png", "info/database.png", "info/db_small.png", "lir.cfg", "txt/lir.txt", "porter/stem.rb", "porter/stem.cfg", "test.cfg", "de/test_mul.txt", "de/test_singleword.txt", "de/test_mul2.txt", "de/test_syn.txt", "de/test_dic.txt", "de/test_syn2.txt", "TODO", "README", "ChangeLog", "COPYING", "Rakefile", "spec/spec_helper.rb", ".rspec", "test/lir.csv", "test/attendee/ts_abbreviator.rb", "test/attendee/ts_noneword_filter.rb", "test/attendee/ts_wordsearcher.rb", "test/attendee/ts_textwriter.rb", "test/attendee/ts_vector_filter.rb", "test/attendee/ts_multiworder.rb", "test/attendee/ts_textreader.rb", "test/attendee/ts_objectfilter.rb", "test/attendee/ts_decomposer.rb", "test/attendee/ts_sequencer.rb", "test/attendee/ts_synonymer.rb", "test/attendee/ts_tokenizer.rb", "test/attendee/ts_variator.rb", "test/mul.txt", "test/test_helper.rb", "test/ref/artikel.ven", "test/ref/lir.csv", "test/ref/artikel.vec", "test/ref/lir.mul", "test/ref/artikel.syn", "test/ref/lir.syn", "test/ref/artikel.mul", "test/ref/artikel.seq", "test/ref/lir.seq", "test/ref/artikel.non", "test/ref/artikel.ver", "test/ref/lir.non", "test/lir2.txt", "test/ts_database.rb", "test/lir.txt", "test/ts_language.rb"]
  s.homepage = "http://lex-lingo.de"
  s.rdoc_options = ["--charset", "UTF-8", "--line-numbers", "--all", "--title", "lingo Application documentation (v1.8.0)", "--main", "README"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9")
  s.rubygems_version = "1.8.13"
  s.summary = "The full-featured automatic indexing system"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-nuggets>, [">= 0.8.2"])
      s.add_runtime_dependency(%q<unicode>, [">= 0"])
      s.add_development_dependency(%q<diff-lcs>, [">= 1.1.3"])
      s.add_development_dependency(%q<open4>, [">= 0"])
    else
      s.add_dependency(%q<ruby-nuggets>, [">= 0.8.2"])
      s.add_dependency(%q<unicode>, [">= 0"])
      s.add_dependency(%q<diff-lcs>, [">= 1.1.3"])
      s.add_dependency(%q<open4>, [">= 0"])
    end
  else
    s.add_dependency(%q<ruby-nuggets>, [">= 0.8.2"])
    s.add_dependency(%q<unicode>, [">= 0"])
    s.add_dependency(%q<diff-lcs>, [">= 1.1.3"])
    s.add_dependency(%q<open4>, [">= 0"])
  end
end
