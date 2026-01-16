classdef BenjaminiYekutieli < nla.net.mcc.Base
    properties (Constant)
        name = "Benjamini-Yekutieli"
    end
    
    methods
        function [is_sig_vector, p_max] = correct(obj, net_atlas, input_struct, prob)
            [is_sig_vector, p_max] = nla.lib.fdr_bh(prob.v, input_struct.prob_max, 'dep');
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            correction_label = sprintf("Benjamini-Yekutieli (alpha = %g)",input_struct.prob_max);
        end
    end
end