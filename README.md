Intended use-case is to declare variables for logging during a simulation run
or similar. Three convenient macros are defined: `@log`, which identifies variables
to be logged, `@lognow`, which creates a snapshot of the logged variables, and
`@logging`, which can be used to decorate a `for`-loop for regularly logging all
variables to be logged.

The to-be-logged variables and the corresponding expressions used to evaluate them
are stored in a

```julia
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
```
