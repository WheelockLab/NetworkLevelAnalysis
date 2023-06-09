classdef Precalculated < nla.edge.BaseTest
    %SIMULATED Load previous simulated data
    properties (Constant)
        name = "Precalculated data"
        coeff_name = "Precalculated coeff"
    end
    
    methods
        function obj = Precalculated()
            import nla.* % required due to matlab package system quirks
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct)
            if input_struct.iteration == 0
                r_vec = input_struct.sim_obs.v;
                p_vec = abs(r_vec);
            else
                r_vec = input_struct.sim_perm.v(:, input_struct.iteration);
                p_vec = abs(r_vec);
            end
            
            fcEdges = length(r_vec);
            fcSquareEdgeSize = (1 + sqrt(1 + 8*fcEdges)) / 2;
            
            result = nla.edge.result.Precalculated(fcSquareEdgeSize, input_struct.prob_max);
            result.name = obj.name;
            result.coeff_name = obj.coeff_name;
            result.coeff.v = r_vec;
            result.prob.v = p_vec;
            result.prob_sig.v = (result.prob.v >= 2);
            result.avg_prob_sig = sum(result.prob_sig.v) ./ numel(result.prob_sig.v);
        end
    end
    
    methods (Static)
        function inputs = requiredInputs()
            import nla.* % required due to matlab package system quirks
            % Precalculated edge-level test doesn't constrain p-value to
            % 0-1 because some people use "p-values" that are not actually
            % p-values and exceed this range.
            inputs = {inputField.Number('prob_max', 'Edge-level P threshold <', 0, 0.05, Inf), inputField.NetworkAtlasPreCalcData()};
        end
    end
end

