classdef BenjaminiHochberg < nla.net.mcc.Base
    properties (Constant)
        name = "Benjamini-Hochberg"
    end
    
    methods (Static)
        function p_max = correct(net_atlas, input_struct, prob)
            import nla.* % required due to matlab package system quirks
            [~, p_max] = lib.fdr_bh(prob.v, input_struct.prob_max, 'pdep');
        end
        function correction_label = createLabel(net_atlas, input_struct, prob)
            import nla.* % required due to matlab package system quirks
            correction_label = sprintf('FDR_{BH}(%g/%d tests)', input_struct.prob_max * input_struct.behavior_count, input_struct.behavior_count);
        end
    end
end