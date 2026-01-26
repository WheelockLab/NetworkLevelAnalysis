classdef Bonferroni < nla.net.mcc.Base
    properties (Constant)
        name = "Bonferroni"
    end
    
    methods
        function [is_sig_vector, p_max] = correct(obj, net_atlas, input_struct, prob)
            
            p_max = input_struct.prob_max / net_atlas.numNetPairs();
            is_sig_vector = prob.v < p_max;
        end
        function correction_label = createLabel(obj, net_atlas, input_struct, prob)
            format_specs_tests = "%d tests)";
            if isequal(input_struct.behavior_count, 1)
                format_specs_tests = "%d test)";
            end
            p_max = input_struct.prob_max / net_atlas.numNetPairs();
            correction_label = sprintf(strcat("P < %.2g (%.2g/%d net-pairs/", format_specs_tests), p_max, input_struct.prob_max * input_struct.behavior_count,...
                net_atlas.numNetPairs(), input_struct.behavior_count);
        end
    end
end