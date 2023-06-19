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
                r_vec = input_struct.precalc_obs_coeff.v;
                p_vec = input_struct.precalc_obs_p.v;
            else
                r_vec = input_struct.precalc_perm_coeff.v(:, input_struct.iteration);
                p_vec = input_struct.precalc_perm_p.v(:, input_struct.iteration);
            end
            
            fcEdges = length(r_vec);
            fcSquareEdgeSize = (1 + sqrt(1 + 8*fcEdges)) / 2;
            
            result = nla.edge.result.Precalculated(fcSquareEdgeSize, input_struct.prob_max);
            result.name = obj.name;
            result.coeff_name = obj.coeff_name;
            result.coeff_range = [input_struct.coeff_min, input_struct.coeff_max];
            result.coeff.v = r_vec;
            result.prob.v = ~p_vec; % p_vec is significance, invert it to get "p-value" (constrained 0-1, decreasing significance)
            result.prob_sig.v = p_vec;
            result.avg_prob_sig = sum(result.prob_sig.v) ./ numel(result.prob_sig.v);
        end
    end
    
    methods (Static)
        function inputs = requiredInputs()
            import nla.* % required due to matlab package system quirks
            npairs_x_nperms = [inputField.DimensionType.NROIPAIRS, inputField.DimensionType.NPERMS];
            npairs_x_1 = [inputField.DimensionType.NROIPAIRS, 1];
            inputs = {inputField.NumberWithoutDefault('coeff_min', 'Coeff minimum', -Inf, Inf), inputField.NumberWithoutDefault('coeff_max', 'Coeff maximum', -Inf, Inf), inputField.NetworkAtlas(), inputField.EdgeLevelMatrix('precalc_obs_p', 'Precalculated observed p', npairs_x_1), inputField.EdgeLevelMatrix('precalc_obs_coeff', 'Precalculated observed coeff', npairs_x_1), inputField.EdgeLevelMatrix('precalc_perm_p', 'Precalculated permuted p', npairs_x_nperms), inputField.EdgeLevelMatrix('precalc_perm_coeff', 'Precalculated permuted coeff', npairs_x_nperms)};
        end
    end
end

