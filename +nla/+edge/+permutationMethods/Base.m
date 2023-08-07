classdef Base
    methods (Abstract)
        permuted_input_struct = permute(obj, orig_input_struct)
    end
end