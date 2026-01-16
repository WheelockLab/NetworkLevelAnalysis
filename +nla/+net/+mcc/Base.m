classdef Base
    methods (Abstract)
        [is_sig_vector, p_max] = correct(obj, net_atlas, input_struct, prob)
        correction_label = createLabel(obj, net_atlas, input_struct, prob)
    end
end