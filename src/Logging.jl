module Logging
using DataFrames


export @log, @logging

#NOTE: there is probably a usecase for logging outside attatching to the loop
#      allows the user to be more consistent for all interesting information
#      they might want to record during an experiment

"""
  For now: no external dependencies, T is the type of data structure or buffer
  the Logger writes to.
"""
struct Logger{T}
    every::Int # how many times during an iteration

    Data::T # the data sink the Logger writes to
end

function Logger()
    # A default Logger logs every iteration into a DataFrame
    return Logger(1, DataFrame())
end

struct CurrentLogger
    nullable::Nullable{Logger}
end

const CURRENT_LOGGER = CurrentLogger(Nullable{Logger})
isloggernull() = isnull(CURRENT_LOGGER.nullable_logger)

function current()
    if isloggernull()
        error("no current logger")
    end
    get(CURRENT_LOGGER.nullable_logger)
end
current(logger::Logger) = (CURRENT_LOGGER.nullable_logger = Nullable(logger))


macro log(expr, names)
    local logger
    try
        logger = current()
    catch
        return new_log(expr, names)
    end
    return append_log!(logger, expr, names)
end

function new_log(expr, names)
    logger = Logger()
    return append_log!(logger, expr, names)
end

function append_log!(logger, expr, names)

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
    current(logger)
    return esc(ex)
end

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
#TODO: varargs arguments for options, will replace @logging from above
#NOTE: other option is to set all options via calls to another fct or something like that and collect
#      default behavior in a Log struct together with a field linked to the actual final data-type
macro logging_varargs(varargs...)
    # last elemenents needs to be a for loop, for now
    loop = varargs[end]
    @assert isa(loop, Expr) && loop.head === :for



    if isa(loop, Expr) && loop.head === :for
        @gensym data
        @gensym counter

        # actual expression to evaluate for logging
        log_action = quote
            if $counter % $every == 1
                push!($data, $__logger_eval(__log_data))
            end
            $counter += 1
        end

        loopbody = loop.args[end]
        @assert loopbody.head === :block
        push!(loopbody.args, log_action)

        # if show_progress==true
        #     loop = quote @showprogress 1 "Simulating ... " 50 $loop end
        # end

        # wapper around the loop
        ex = quote
            __log_data = __log_data # make local log available for read/write
            $counter = 1
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
end
