# encoding: utf-8

require_relative 'bench_helper'
require_optional 'sdbm', 'gdbm', 'depot', 'sqlite3', %w[cdb cdb-full], 'libcdb'

module StoreBench

  F = ENV['BENCH_FILE'] || File.join(Bench::DIR, '../dict/de/lingo-dic.txt')

  N = (ENV['BENCH_CREATE'] || 10   ).to_i
  M = (ENV['BENCH_READ']   || N * 2).to_i

  A = File.readlines(F).each(&:strip!).
    delete_if { |l| l.empty? || l.start_with?('#') }.
    map! { |l| l.split('=', 2) }

  B = A.map(&:first).shuffle!

  # stdlib
  def sdbm(c = false)
    yield d = SDBM.open(tempfile(:sdbm, c, '.*'))
  ensure
    d.close
  end

  # stdlib (when compiled with GDBM headers) OR
  # https://github.com/presidentbeef/ffi-gdbm (gem install gdbm)
  def gdbm(c = false)
    GDBM.open(tempfile(:gdbm, c)) { |d| yield d }
  end

  # http://fallabs.com/qdbm/ (compile manually; needs modification for Ruby 1.9)
  def depot(c = false)
    m = c ? Depot::OWRITER | Depot::OCREAT : Depot::OREADER
    Depot.open(tempfile(:depot, c), m) { |d| yield d }
  end

  # http://github.com/luislavena/sqlite3-ruby (gem install sqlite3) [VERY SLOW!]
  def sqlite(c = false)
    return yield Bench[:sqlite] if Bench[:sqlite] && !c

    d = SQLite3::Database.new(f = ENV['BENCH_SQLITE'] || tempfile(:sqlite, c))

    if c
      d.execute('CREATE TABLE b (k TEXT PRIMARY KEY, v TEXT)')

      if m = f.empty? || f == ':memory:'
        Bench[:sqlite].close if Bench[:sqlite]
        Bench[:sqlite] = d
      end
    end

    yield d
  ensure
    d.close if d && !m
  end

  # http://www.fan.gr.jp/~kaz/ruby/ (gem install cdb-full)
  def cdbmake(c = false)
    (c ? CDBMake : CDB).open(tempfile(:cdb, c)) { |d| yield d }
  end

  # https://github.com/mbj/ruby-cdb (doesn't work on Ruby 1.9!)
  #
  # create: d.store(k, v)
  # read:   d.each_for_key(k) { |v| break v }
  #def cdb(c = false)
  #  File.open(tempfile(:cdb, c), c ? 'w' : 'r') { |i|
  #    c ? CDB::CDBMaker.fill(i) { |d| yield d } : yield(CDB::CDBReader.new(i))
  #  }
  #end

  def libcdb(c = false)
    LibCDB::CDB.open(tempfile(:libcdb, c), c ? 'w' : 'r') { |d| yield d }
  end

  def create(s, f = nil)
    run(s, N, :create, f) { |m| send(m, true) { |d| A.each { |k, v| yield d, k, v } } }
  end

  def read(s, f = nil)
    run(s, M, :read, f) { |m| send(m) { |d| B.each { |k| yield d, k } } }
  end

end

Bench.bench(StoreBench) { |x|
  x.create(:SQLite3)   { |d, k, v| d.execute('REPLACE INTO b (k,v) VALUES (?,?)', [k, v]) }
  x.create(:GDBM)      { |d, k, v| d[k] = v }
  x.create(:Depot)     { |d, k, v| d[k] = v }
  x.create(:SDBM)      { |d, k, v| d[k] = v }
  x.create(:LibCDB)    { |d, k, v| d[k] = v }
  x.create(:LibCDB, 2) { |d, k, v| d.add(k, v) }
  x.create(:CDBMake)   { |d, k, v| d[k] = v }

  x.read(:SQLite3)     { |d, k| d.get_first_value('SELECT v FROM b WHERE k = ?', k) }
  x.read(:GDBM)        { |d, k| d[k] }
  x.read(:Depot)       { |d, k| d[k] }
  x.read(:SDBM)        { |d, k| d[k] }
  x.read(:LibCDB)      { |d, k| d[k] }
  x.read(:CDBMake, 2)  { |d, k| r = nil; d.each(k) { |v| r = v }; r }
  x.read(:CDBMake)     { |d, k| d[k] }
}
