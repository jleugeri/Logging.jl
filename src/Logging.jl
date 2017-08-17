module Logging
using DataFrames


export @log, @logging

macro log(expr, names)
    # generate symbols that can be used for temporary objects in the macro expansion
    @gensym esymb nsymb
    ex = quote
        # evaluate the names in the calling scope, but wrap the tracking expressions into a function closure
        $nsymb = eval($names)
        $esymb = ()->$expr
        __log_data = try
            append!(__log_data[1], $nsymb)
            push!(__log_data[2], $esymb)
            __log_data
        catch err
            ([[]; $nsymb], Any[$esymb])
        end
    end
    esc(ex)
end
# Syntax:  @log obj.attr
# or:      @log [...] [...]

__logger_eval(log) = foldl((vals,fun)->[vals; fun()], [], log[2])

"""
    @logging(loop::Expr)
  The base functionality of the macro logging during a for loop.
"""
macro logging(loop::Expr)
    if isa(loop, Expr) && loop.head === :for
        @gensym data

        # actual expression to evaluate for logging
        log_action = quote
            push!($data, $__logger_eval(__log_data))
        end

        loopbody = loop.args[end]
        @assert loopbody.head === :block
        push!(loopbody.args, log_action)

        # wapper around the loop
        ex = quote
            __log_data = __log_data # make local log available for read/write
            let
                $data = $DataFrame(map(typeof, $__logger_eval(__log_data)), map(Symbol, __log_data[1]), 0)
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
