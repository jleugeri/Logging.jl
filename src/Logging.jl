module Logging
using DataFrames


export @log, @logging, @lognow

"""
    @log <expr1> <name1> [logger]
    @log [Any[<expr1>,...]] [String[<name1>,...]] [logger]

    Stores an expression or an array of expressions under corresponding names into the (optionally) specified logger dictionary.
    This logger dictionary can be used in combination with the @lognow and @logging macros to log data.

    Caution: the logger dictionary is defined in the local scope of the evaluation of @log.
    If this happens within a hard local scope, the logger dictionary may be out of scope when
    a logging macro such as @lognow or @logging is called. This can be prevented by declaring an
    apropriate logger dictionary in a common parent scope and passing it as the last argument to the macros.
"""
macro log(expr, names, logger::Symbol=:__log_data)
    # generate symbols that can be used for temporary objects in the macro expansion
    @gensym esymb nsymb T
    ex = quote
        # evaluate the names in the calling scope, but wrap the tracking expressions into a function closure
        $nsymb = eval($names)
        $T = typeof(eval($expr))
        function $esymb()::$T
            convert($T, $expr)
        end

        $logger = try
            append!($logger[1], $nsymb)
            push!($logger[2], $esymb)
            $logger
        catch err
            (String[[]; $nsymb], Function[$esymb])
        end
    end
    esc(ex)
end

@inline __logger_eval(log)::Vector{Any} = foldl((vals,fun)->Any[vals; fun()], Any[], log[2])

"""
    @lognow [data storage] [logger dict]
    Log all variables tracked in the logger dict into the data storage.
"""
macro lognow(data::Symbol = :__log, logger::Symbol = :__log_data)
    esc(quote
        $data = try
            push!($data, Logging.__logger_eval($logger))
            $data
        catch err
            $data = DataFrames.DataFrame(map(typeof, Logging.__logger_eval($logger)), map(Symbol, $logger[1]), 0)
            push!($data, Logging.__logger_eval($logger))
            $data
        end
    end)
end

"""
    @logging(loop::Expr)
  The base functionality of the macro logging during a for loop.
"""
macro logging(loop::Expr, logger::Symbol = :__log_data)
    if isa(loop, Expr) && loop.head === :for
        @gensym data

        # actual expression to evaluate for logging
        log_action = quote
            push!($data, $__logger_eval($logger))
        end

        loopbody = loop.args[end]
        @assert loopbody.head === :block
        push!(loopbody.args, log_action)

        # wapper around the loop
        ex = quote
            $logger = $logger # make local log available for read/write
            let
                $data = $DataFrame(map(typeof, $__logger_eval($logger)), map(Symbol, $logger[1]), 0)
                $loop
                $data
            end
        end
        esc(ex)
    else
        throw(ArgumentError("The last argument to @logging must be a for loop."))
    end
end

# Johannes' version, currently commented out for the most simple variant.
#TODO: varargs arguments for options
# macro logging(every::Integer, data::Symbol, show_progress::Bool, loop::Expr)
# macro logging(every::Integer, loop::Expr)
#     if isa(loop, Expr) && loop.head === :for
#         @gensym data
#         @gensym counter
#
#         # actual expression to evaluate for logging
#         log_action = quote
#             if $counter % $every == 1
#                 push!($data, $__logger_eval(__log_data))
#             end
#             $counter += 1
#         end
#
#         loopbody = loop.args[end]
#         @assert loopbody.head === :block
#         push!(loopbody.args, log_action)
#
#         # if show_progress==true
#         #     loop = quote @showprogress 1 "Simulating ... " 50 $loop end
#         # end
#
#         # wapper around the loop
#         ex = quote
#             __log_data = __log_data # make local log available for read/write
#             $counter = 1
#             let
#                 $data = $DataFrame(map(typeof, $__logger_eval(__log_data)), map(Symbol, __log_data[1]), 0)
#                 $loop
#                 $data
#             end
#         end
#         esc(ex)
#     else
#         throw(ArgumentError("The last argument to @logging must be a for loop."))
#     end
# end
end
