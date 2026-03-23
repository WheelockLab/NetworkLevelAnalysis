classdef Bonferroni < nla.net.mcc.Base
    properties (Constant)
        name = "Bonferroni"
    end
    
    methods
        function [is_sig_vector, p_max] = correct(obj, net_atlas, input_struct, prob)
            
            p_max = input_struct.prob_max / net_atlas.numNetPairs();
            is_sig_vector = prob.v < p_max;
        end
        function correction_label = createLabel(obj, net_atlas, input_struct)
            
            p_max = input_struct.prob_max / net_atlas.numNetPairs();
            correction_label = sprintf("P < %.2g (%.2g/%d net-pairs)", p_max, input_struct.prob_max,...
                net_atlas.numNetPairs());
        end
    end
end