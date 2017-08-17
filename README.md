Intended usecase is to declare variables for logging during a simulation run
or similar.
```
function fib_logging()
  F0 = 0
  F1 = 1
  @log F0 "Fib"

  @logging for i in ∈ 1:10
    new_F = F0 + F1
    F0 = F1
    F1 = new_F
  end
end

data = fib_logging();
```
