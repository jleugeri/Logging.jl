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
  @log F0 "Fib"

  @logging for i ∈ 1:10
    new_F = F0 + F1
    F0 = F1
    F1 = new_F
  end
end

data = fib_logging()
