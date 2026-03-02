classdef None < nla.net.mcc.Base
    properties (Constant)
        name = "None"
    end
    
    methods
        function [is_sig_vector, p_max] = correct(obj, net_atlas, input_struct, prob)            
            p_max = input_struct.prob_max;
            is_sig_vector = prob.v < p_max;
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            format_specs = "P < %.2g (%g/%d tests)";
            if isequal(input_struct.behavior_count, 1)
                format_specs = "P < %.2g (%g/%d test)";
            end
            correction_label = sprintf(format_specs, input_struct.prob_max, input_struct.prob_max * input_struct.behavior_count,...
                input_struct.behavior_count);
        end
    end
end