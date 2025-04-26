classdef UnconstrainedBlocks_Mex < nla.helpers.stdError.UnconstrainedBlocks
    
    methods
        
        function stdErr = calculate(obj, sweStdErrInput)            
            %Half sandwich algorithm implemented in C by Ty To
            %NON WALD TEST version
            
            %rename variables for readability
            pinvDesignMtx = sweStdErrInput.pinvDesignMtx;
            residual = sweStdErrInput.residual;
            groupIds = sweStdErrInput.scanMetadata.groupId;
            unqGrps = unique(groupIds);
            
            obj.throwErrorIfVEntirelyFull(unqGrps);
            
            
            covB = nla.mex.bin.mexSandwichEstimator(residual, pinvDesignMtx, groupIds);
            
            
            stdErr = sqrt(covB);
            

        end
        
    end

end