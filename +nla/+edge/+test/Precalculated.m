classdef Precalculated < nla.edge.BaseTest
    %SIMULATED Load previous simulated data
    properties (Constant)
        name = "Precalculated data"
        coeff_name = "Precalculated coeff"
    end
    
    methods
        function obj = Precalculated()
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
            
            result = nla.edge.result.Precalculated(input_struct.net_atlas.numROIs(), input_struct.prob_max);
            % p_vec is significance, invert it to get "p-value" (constrained 0-1, decreasing significance)
            obj.setResultFields(input_struct.net_atlas, result, r_vec, ~p_vec, input_struct.prob_max);
            result.prob_sig.v = p_vec;
            result.avg_prob_sig = sum(result.prob_sig.v) ./ numel(result.prob_sig.v);
            result.coeff_range = [input_struct.coeff_min, input_struct.coeff_max];
        end
    end
    
    methods (Static)
        function inputs = requiredInputs()
            import nla.inputField.DimensionType nla.inputField.NumberWithoutDefault nla.inputField.EdgeLevelMatrix

            npairs_x_nperms = [DimensionType.NROIPAIRS,DimensionType.NPERMS];
            npairs_x_1 = [DimensionType.NROIPAIRS, 1];
            inputs = {...
                NumberWithoutDefault('coeff_min', 'Coeff minimum', -Inf, Inf),...
                NumberWithoutDefault('coeff_max', 'Coeff maximum', -Inf, Inf),...
                nla.inputField.NetworkAtlas(),...
                EdgeLevelMatrix('precalc_obs_p', 'Precalculated observed significance (thresholded p-value)', npairs_x_1),...
                EdgeLevelMatrix('precalc_obs_coeff', 'Precalculated observed coeff', npairs_x_1),...
                EdgeLevelMatrix('precalc_perm_p', 'Precalculated permuted significance (thresholded p-value)', npairs_x_nperms),...
                EdgeLevelMatrix('precalc_perm_coeff', 'Precalculated permuted coeff', npairs_x_nperms)...
            };
        end
    end
end

