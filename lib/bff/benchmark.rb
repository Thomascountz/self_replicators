require "benchmark/ips"
require_relative "interpreter"

[
  {description: "Add Five", tape: "<+++++\x00".freeze},
  {description: "Count Down", tape: "<[-]\xFF".freeze},
  {description: "Infinite Loop", tape: "<[-+]\x00".freeze},
  {description: "Unbalanced Loop", tape: "<[+\x01".freeze},
  {description: "Nested Loops", tape: "<[<[<[-]>-]>-]\xFF\xFF\xFF".freeze}
].each do |test_case|
  Benchmark.ips do |bm|
    description = test_case[:description]
    tape = test_case[:tape]

    bm.report(description) do
      BFF::Interpreter.run(tape)
    end
  end
end

__END__


ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]
Warming up --------------------------------------
            Add Five    68.066k i/100ms
Calculating -------------------------------------
            Add Five    684.392k (± 0.2%) i/s    (1.46 μs/i) -      3.471M in   5.072198s
ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]
Warming up --------------------------------------
          Count Down   986.000 i/100ms
Calculating -------------------------------------
          Count Down      9.913k (± 0.7%) i/s  (100.87 μs/i) -     50.286k in   5.072785s
ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]
Warming up --------------------------------------
       Infinite Loop    88.421k i/100ms
Calculating -------------------------------------
       Infinite Loop    893.422k (± 0.4%) i/s    (1.12 μs/i) -      4.509M in   5.047497s
ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]
Warming up --------------------------------------
     Unbalanced Loop   105.470k i/100ms
Calculating -------------------------------------
     Unbalanced Loop      1.048M (± 0.4%) i/s  (953.91 ns/i) -      5.274M in   5.030532s
ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]
Warming up --------------------------------------
        Nested Loops   129.000 i/100ms
Calculating -------------------------------------
        Nested Loops      1.257k (± 2.1%) i/s  (795.43 μs/i) -      6.321k in   5.030094s
