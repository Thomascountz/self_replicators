require "benchmark/ips"
require_relative "interpreter"

ZERO = 0.chr
TWOFIFTYFIVE = 255.chr

def add_five
  "<+++++\x00"
end

def count_down
  "<[-]\xFF"
end

def infinite_loop
  "<[-+]\x00"
end

def unbalanced_parens
  "<[+\x01"
end

def nested_loops
  "<[<[<[-]>-]>-]\xFF\xFF\xFF"
end

[:add_five, :count_down, :infinite_loop, :unbalanced_parens, :nested_loops].each do |method|
  Benchmark.ips do |bm|
    bm.report(method) do
      BFF::Interpreter.run(send(method))
    end
  end
end

__END__


ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]
Warming up --------------------------------------
            add_five    57.117k i/100ms
Calculating -------------------------------------
            add_five    561.747k (± 0.7%) i/s    (1.78 μs/i) -      2.856M in   5.084106s
ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]
Warming up --------------------------------------
          count_down   972.000 i/100ms
Calculating -------------------------------------
          count_down      9.753k (± 0.3%) i/s  (102.54 μs/i) -     49.572k in   5.082957s
ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]
Warming up --------------------------------------
       infinite_loop    71.895k i/100ms
Calculating -------------------------------------
       infinite_loop    718.920k (± 0.2%) i/s    (1.39 μs/i) -      3.595M in   5.000231s
ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]
Warming up --------------------------------------
        nested_loops   128.000 i/100ms
Calculating -------------------------------------
        nested_loops      1.282k (± 1.1%) i/s  (780.19 μs/i) -      6.528k in   5.093731s


