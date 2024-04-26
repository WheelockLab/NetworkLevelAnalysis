classdef BenjaminiHochberg < nla.net.mcc.Base
    properties (Constant)
        name = "Benjamini-Hochberg"
    end
    
    methods
        function p_max = correct(obj, net_atlas, input_struct, prob)
            [~, p_max] = nla.lib.fdr_bh(prob.v, input_struct.prob_max, 'pdep');
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            p_max = obj.correct(net_atlas, input_struct, prob);
            if p_max == 0
                correction_label = sprintf('FDR_{BH} produced no significant nets');
            else
                correction_label = sprintf('FDR_{BH}(%g/%d tests)', input_struct.prob_max * input_struct.behavior_count,...
                    input_struct.behavior_count);
            end
        end
    end
end