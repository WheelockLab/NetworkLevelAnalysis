classdef BaseTest < nla.Test
    %BASETEST Base class of tests performing edge-level analysis
    % The intended behavior of the run function of an edge-leve test is that
    % it creates a new result object on the nonpermuted run and accepts
    % said result as previous_result on all subsequent permuted runs,
    % modifying it.
    
    methods
        function obj = BaseTest()
        end
    end
    
    methods (Access = protected)
        function result = composeResult(obj, net_atlas, rho_vec, p_vec, prob_max)
            result = nla.edge.result.Base(net_atlas.numROIs(), prob_max);
            obj.setResultFields(net_atlas, result, rho_vec, p_vec, prob_max);
        end
        
        function result = setResultFields(obj, net_atlas, result, rho_vec, p_vec, prob_max)
            result.name = obj.name;
            result.coeff_name = obj.coeff_name;
            result.coeff.v = rho_vec;
            result.prob.v = p_vec;
            result.prob_sig.v = (result.prob.v < prob_max);
            result.avg_prob_sig = sum(result.prob_sig.v) ./ numel(result.prob_sig.v);
        end
    end
    
    methods (Abstract)
        run(obj, input_struct, previous_result)
    end
    
    methods (Static)
        function inputs = requiredInputs()
            inputs = {nla.inputField.Number('prob_max', 'Edge-level P threshold <', 0, 0.05, 1),...
                nla.inputField.NetworkAtlasFuncConn(), nla.inputField.Behavior()};
        end
    end
end
