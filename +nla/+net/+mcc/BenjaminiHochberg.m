classdef BenjaminiHochberg < nla.net.mcc.Base
    properties (Constant)
        name = "Benjamini-Hochberg"
    end
    
    methods
        function [is_sig_vector, p_max] = correct(obj, net_atlas, input_struct, prob)
            [is_sig_vector, p_max] = nla.lib.fdr_bh(prob.v, input_struct.prob_max, 'pdep');
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            correction_label = sprintf("Benjamini-Hochberg (alpha = %g)",input_struct.prob_max);
        end
    end
end