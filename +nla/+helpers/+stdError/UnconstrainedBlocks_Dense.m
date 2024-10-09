classdef UnconstrainedBlocks_Dense < nla.helpers.stdError.UnconstrainedBlocks

    methods
        
        function stdErr = calculate(obj, sweStdErrInput)
            %Computes Standard Error assuming unconstrained blocks
            %Uses standard matrix multiplication to compute standard error,
            %since it does not make assumption that V is sparse.
                        
            
            %rename variables for readability
            pinvDesignMtx = sweStdErrInput.pinvDesignMtx;
            residual = sweStdErrInput.residual;
            groupIds = sweStdErrInput.scanMetadata.groupId;
            unqGrps = unique(groupIds);
            numGrps = length(unqGrps);
            
            obj.throwErrorIfVEntirelyFull(unqGrps);
            
            [numCovariates, numObs] = size(pinvDesignMtx);
            [~,numFcEdges] = size(residual);
            
            %Preallocate size of stdErr output
            stdErr = zeros(numCovariates, numFcEdges);
            
            %Reorder data so that grouped observations are together
            [pinvDesignMtx_grp, residual_grp, groupIds_grp] = obj.reorderDataByGroup(pinvDesignMtx, residual, groupIds);
                        
            %Determine which observations fit in which group once, outside
            %of loop for fc edges
            inGroupFlags = zeros(numObs, numGrps);
            for grpIdx = 1:numGrps
                thisGrpId = unqGrps(grpIdx);
                inGroupFlags(:,grpIdx) = (groupIds_grp == thisGrpId);
            end
            
            %For each fc edge, build the V and multiply it by
            %pinvDesignMatrix on both sides
            thisV = zeros(numObs, numObs);
            
            for fcIdx = 1:numFcEdges
                
                thisV(:,:) = 0;
                for grpIdx = 1:numGrps
                    thisGrpFlags = logical(inGroupFlags(:,grpIdx));
                    residThisGrp = residual_grp(thisGrpFlags,fcIdx);
                    thisGrpVBlock = residThisGrp * residThisGrp';
                    thisV(thisGrpFlags,thisGrpFlags) = thisGrpVBlock;
                end
                
                thisBetaCovar = pinvDesignMtx_grp * thisV * pinvDesignMtx_grp';
                stdErr(:,fcIdx) = sqrt(diag(thisBetaCovar));
                
            end
            

        end       
        
    end       
   

end