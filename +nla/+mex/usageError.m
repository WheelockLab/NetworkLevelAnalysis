function usageError(err)
    %USAGEERROR Throw an error with a message explaining how to use the
    % mex.run function.
    error("%s\nmex.run usage: [val1, val2, ... valN] = mex.run(func_name, arg1, arg2, ... argN)", err)
end

