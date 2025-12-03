classdef FCWildBootstrap < nla.edge.permutationMethods.Base
    methods
        function permuted_input_struct = permute(obj, orig_input_struct, ~)
            permuted_input_struct = orig_input_struct;
            permuted_input_struct.func_conn = orig_input_struct.func_conn.copy();
            fcData = permuted_input_struct.func_conn.v';
            permuted_fcData = nla.helpers.wildBootstrap(fcData, [orig_input_struct.behavior, orig_input_struct.covariates], orig_input_struct.contrasts);
            permuted_input_struct.func_conn.v = permuted_fcData';
        end
    end
end
