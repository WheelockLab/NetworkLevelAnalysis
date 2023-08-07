classdef Bonferroni < nla.net.correctFDR.Base
    properties (Constant)
        name = "Bonferroni"
    end
    
    methods (Static)
        function p_max = correct(net_atlas, input_struct, prob)
            import nla.* % required due to matlab package system quirks
            p_max = input_struct.prob_max / net_atlas.numNetPairs();
        end
        function correction_label = createLabel(net_atlas, input_struct, prob)
            import nla.* % required due to matlab package system quirks
            correction_label = sprintf('%g/%d net-pairs/%d tests', input_struct.prob_max * input_struct.behavior_count, net_atlas.numNetPairs(), input_struct.behavior_count);
        end
    end
end