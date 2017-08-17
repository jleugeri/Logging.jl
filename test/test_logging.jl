include("../src/Logging.jl")
using Logging, ProgressMeter

################################################################################
#     Test case: simple for loop, logging mutable variables from local scope   #
################################################################################

mutable struct Test
    a::Int64
end

f() = begin
    # Define some objects to track
    t1, t2, a = Test(3), Test(5), "Say what."

    # log individual variable
    @log a "a"

    # loop over variables to log
    for (i,t) in enumerate([t1, t2])
        @log t.a "$i"
    end

    # define a whole batch of variables to log
    @log [t.a for t ∈ [t1, t2]] ["$i" for i in 3:4]

    # run a for loop, where every 100th step all variables of interest are logged
    # the result is a DataFrame object
    result = @logging 100 true for i ∈ 1:10000000
        t1.a = rand(1:10)
        t2.a = div(i,2)
        a = "I'm $(t1.a) years old!"
    end
end

f()
@time d=f()
d
