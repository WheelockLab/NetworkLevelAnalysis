classdef None < nla.net.mcc.Base
    properties (Constant)
        name = "None"
    end
    
    methods
        function [is_sig_vector, p_max] = correct(obj, net_atlas, input_struct, prob)            
            p_max = input_struct.prob_max;
            is_sig_vector = prob.v < p_max;
        end
        function correction_label = createLabel(obj, net_atlas, input_struct)            
            correction_label = sprintf("P < %.2g", input_struct.prob_max);
        end
    end
end