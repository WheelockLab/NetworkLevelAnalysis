classdef FcWildBootstrap < nla.permutemethods.AbstractPermute
    
    methods
        
        function permuted_input_struct = permute(obj, orig_input_struct)
            
            permuted_input_struct = orig_input_struct;  
            
            permuted_fcData = ...
                    nla.helpers.wildBootstrap(...
                                            orig_input_struct.fcData, ...
                                            orig_input_struct.covariates, ...
                                            orig_input_struct.contrasts);
                                 
            permuted_input_struct.fcData = permuted_fcData;            
            
        end
        
    end
    
end