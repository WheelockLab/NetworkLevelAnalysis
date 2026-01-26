classdef HolmBonferroni < nla.net.mcc.Base
    properties (Constant)
        name = "Holm-Bonferroni"
    end

    methods
        function [is_sig_vector, p_max] = correct(obj, net_atlas, input_struct, prob)
            [is_sig_vector, adjusted_pvals, ~] = nla.lib.bonferroni_holm(prob.v, input_struct.prob_max);
                        
            p_max = max(is_sig_vector .* prob.v);
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            correction_label = sprintf("Holm-Bonferroni (alpha = %g)",input_struct.prob_max);
            
            %Since p threshold is variable with this test, exclude it and
            %just use the initial 'alpha' term used in the algorithm.
        end
    end
end
