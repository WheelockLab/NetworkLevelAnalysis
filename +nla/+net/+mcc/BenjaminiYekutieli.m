classdef BenjaminiYekutieli < nla.net.mcc.Base
    properties (Constant)
        name = "Benjamini-Yekutieli"
    end
    
    methods
        function p_max = correct(obj, net_atlas, input_struct, prob)
            [~, p_max] = nla.lib.fdr_bh(prob.v, input_struct.prob_max, 'dep');
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            p_max = obj.correct(net_atlas, input_struct, prob);
            if p_max == 0
                correction_label = sprintf('FDR_{BY} produced no significant nets');
            else
                format_specs = "%g/%d tests";
                if isequal(input_struct.behavior_count, 1)
                    format_specs = "%g/%d test";
                end
                correction_label = sprintf(strcat("FDR_{BY}(", format_specs, ")"), input_struct.prob_max * input_struct.behavior_count,...
                    input_struct.behavior_count);
            end
        end
    end
end