"""
  A simple example: Calculate the Fibbonaci sequences, log the result in
  a data-frame!
"""
### UNTIL PROPER MODULE ON THE PATH
str_path = string(pwd(), "/src/Logging.jl")
include(str_path)

using Logging

function fib_logging()
  F0 = 0
  F1 = 1
  @log F0 "Fib" mylogger

  @logging for i ∈ 1:10
    new_F = F0 + F1
    F0 = F1
    F1 = new_F
  end mylogger
end

function fib_lognow()
  F0 = 0
  F1 = 1
  @log F0 "Fib"

  results = DataFrames.DataFrame()
  for i ∈ 1:10
    new_F = F0 + F1
    F0 = F1
    F1 = new_F
    @lognow results
  end

  return results
end

data1 = fib_logging()
data2 = fib_lognow()

println("Using @logging:")
show(data1)
println("\nUsing @lognow:")
show(data2)
println("\n")
