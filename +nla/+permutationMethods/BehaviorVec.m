classdef BehaviorVec < nla.permutationMethods.AbstractPermute
    
    methods
        
        function permuted_input_struct = permute(obj, orig_input_struct)
            
            permuted_input_struct = orig_input_struct;            
            permuted_behavior = nla.helpers.permuteVector(orig_input_struct.behavior);            
            permuted_input_struct.behavior = permuted_behavior;            
            
        end
        
    end
    
end