classdef None < nla.net.mcc.Base
    properties (Constant)
        name = "None"
    end
    
    methods
        function p_max = correct(obj, net_atlas, input_struct, prob)
            p_max = input_struct.prob_max;
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            correction_label = sprintf('%g/%d tests', input_struct.prob_max * input_struct.behavior_count,...
                input_struct.behavior_count);
        end
    end
end