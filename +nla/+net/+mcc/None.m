classdef None < nla.net.mcc.Base
    properties (Constant)
        name = "None"
    end
    
    methods (Static)
        function p_max = correct(net_atlas, input_struct, prob)
            import nla.* % required due to matlab package system quirks
            p_max = input_struct.prob_max;
        end
        function correction_label = createLabel(net_atlas, input_struct, prob)
            import nla.* % required due to matlab package system quirks
            correction_label = sprintf('%g/%d tests', input_struct.prob_max * input_struct.behavior_count, input_struct.behavior_count);
        end
    end
end