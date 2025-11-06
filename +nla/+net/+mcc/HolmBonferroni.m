classdef HolmBonferroni < nla.net.mcc.Base
    properties (Constant)
        name = "Holm-Bonferroni"
    end

    methods
        function p_max = correct(obj, net_atlas, input_struct, prob)
            [is_significant, adjusted_pvals, ~] = nla.lib.bonferroni_holm(prob.v, input_struct.prob_max);
            p_max = max(is_significant .* adjusted_pvals);
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            p_max = obj.correct(net_atlas, input_struct, prob);
            if p_max == 0
                correction_label = sprintf('Holm-Bonferroni produced no significant networks');
            else
                format_specs = "%g/%d tests";
                if isequal(input_struct.behavior_count, 1)
                    format_specs = "%g/%d test";
                end
                correction_label = sprintf(strcat("Holm-Bonferroni(", format_specs, ")"), input_struct.prob_max * input_struct.behavior_count,...
                    input_struct.behavior_count);
            end
        end
    end
end
