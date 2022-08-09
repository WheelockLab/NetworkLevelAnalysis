classdef BaseTest < nla.Test
    %BASETEST Base class of tests performing edge-level analysis
    % The intended behavior of the run function of an edge-leve test is that
    % it creates a new result object on the nonpermuted run and accepts
    % said result as previous_result on all subsequent permuted runs,
    % modifying it.
    
    methods
        function obj = BaseTest()
            import nla.* % required due to matlab package system quirks
        end
    end
    
    methods (Access = protected) 
        function result = updateResult(obj, input_struct, rho_vec, p_vec, previous_result)
            import nla.* % required due to matlab package system quirks
            % rho: column vector of rho values(often fisher Z transformed)
            % p: column vector of p values
            
            if previous_result ~= false
                % Permuted
                result = previous_result;
                result.perm_count = result.perm_count + 1;
            else
                % Non-permuted
                result = nla.edge.result.Base(input_struct.func_conn.size, input_struct.prob_max);
            end
            
            result.coeff.v = rho_vec;
            result.prob.v = p_vec;
            result.prob_sig.v = (result.prob.v < input_struct.prob_max);
            result = obj.updateResult2(result);
        end
        
        function result = updateResult2(obj, result)
            import nla.* % required due to matlab package system quirks
            
            if result.perm_count == 0
                result.name = obj.name;
                result.coeff_name = obj.coeff_name;
            end
            
            result.avg_prob_sig = sum(result.prob_sig.v) ./ numel(result.prob_sig.v);
            
            if result.perm_count ~= 0
                result.coeff_perm(:, :, result.perm_count) = result.coeff.asMatrix();
                result.prob_perm(:, :, result.perm_count) = result.prob_sig.asMatrix();
            end
        end
    end
    
    methods (Abstract)
        run(obj, input_struct, previous_result)
    end
    
    methods (Static)
        function inputs = requiredInputs()
            import nla.* % required due to matlab package system quirks
            inputs = {inputField.Number('prob_max', 'Edge-level P threshold <', 0, 0.05, 1), inputField.NetworkAtlas(), inputField.Behavior()};
        end
    end
end
