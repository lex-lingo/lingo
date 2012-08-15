# encoding: utf-8

require 'benchmark'

def require_optional(*args)
  args.each { |lib, name|
    next if ENV["LINGO_NO_#{lib.upcase[/\D+/]}"]

    begin
      gem name if name
      require lib
    rescue LoadError => err
      warn "Skipping #{lib}... (#{err})" if $VERBOSE
    end
  }
end

module Bench

  extend self

  VAR, GCPROF = {}, {}

  DIR = File.dirname(__FILE__)

  module BenchHelper

    def tempfile(name, create, ext = nil)
      file = File.join(Bench::DIR, "tmp.#{name}")

      if create
        delete = ext ? Dir["#{file}#{ext}"] : File.exist?(file) ? file : nil
        File.delete(*delete) if delete
      end

      file
    end

    def run(symbol, count = 1, prefix = nil, suffix = nil)
      return unless count > 0 && Object.const_defined?(symbol)

      name  = symbol.downcase[/\D+/]
      label = "#{prefix} #{name}#{suffix}".strip

      report(label) { Bench.gcprof(label) { count.times { yield name } } }
    end

  end

  def bench(*mod)
    Benchmark.bmbm { |job|
      job.extend(BenchHelper, *mod)

      yield job

      VAR[:report_width] = job.width + 1
    }

    gcreport
  end

  def memory
    return unless File.readable?(file = "/proc/#{Process.pid}/smaps")

    rss = shar = priv = 0

    heap = false

    File.foreach(file) { |line|
      if line =~ /\d+.+\[heap\]/
        heap = true
      elsif heap
        case line
          when /Rss:\s+(\d+)/
            rss += $1.to_i
          when /(?:Shared_Clean|Shared_Dirty):\s+(\d+)/
            shar += $1.to_i
          when /Private_Clean:\s+(\d+)/
            priv += $1.to_i
          when /Private_Dirty:\s+(\d+)/
            priv += $1.to_i
            break
        end
      end
    }

    [rss, shar, priv]
  end

  def gcprof(label)
    return yield if GCPROF[label]

    GC::Profiler.enable
    mem, count = memory, GC.count

    yield

    count, time = GC.count - count, GC::Profiler.total_time
    memory.each_with_index { |val, idx| mem[idx] = val - mem[idx] } if mem

    GCPROF[label] = [count, time, *mem]
  ensure
    GC::Profiler.disable
    GC::Profiler.clear
  end

  def gcreport
    return if GCPROF.empty?

    puts

    prefix = "%-#{VAR[:report_width]}s"
    header = "#{prefix} %6s  %6s  %8s  %8s  %8s"
    format = "#{prefix} %6d  %0.4f  %8s  %8s  %8s"

    columns = format.count('%') - prefix.count('%')

    puts header % ['', 'gc', 'time', 'rss', 'shared', 'private']

    GCPROF.each { |label, prof|
      puts format % [label, *prof.fill('n/a', size = prof.size, columns - size)]
    }
  end

  def [](key)
    VAR[key]
  end

  def []=(key, val)
    VAR[key] = val
  end

end
