classdef HolmBonferroni < nla.net.mcc.Base
    properties (Constant)
        name = "Holm-Bonferroni"
    end

    methods
        function p_max = correct(obj, net_atlas, input_struct, prob)
            [is_significant, adjusted_pvals, ~] = nla.lib.bonferroni_holm(prob.v, input_struct.prob_max);
            
            %We need to generate a p_max threshold where all nets marked
            %'is_significant' are strictly below it. We can accomplish this
            %by finding the highest p value that passes and adding a small
            %delta that is unlikely to allow any additional net pairs
            %through the threshold
            DELTA = 1e-10;
            p_max = max(is_significant .* prob.v)+DELTA;
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            correction_label = sprintf("Holm-Bonferroni (alpha = %g)",input_struct.prob_max);
            
            %Since p threshold is variable with this test, exclude it and
            %just use the initial 'alpha' term used in the algorithm.
        end
    end
end
