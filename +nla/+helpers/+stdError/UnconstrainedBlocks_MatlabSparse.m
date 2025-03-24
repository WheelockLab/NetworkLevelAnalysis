classdef UnconstrainedBlocks_MatlabSparse < nla.helpers.stdError.UnconstrainedBlocks

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
            
            %To prepare sparse matrix, find number of entries for each group
            [subjPerGrp,~] = groupcounts(groupIds_grp);
            totalNonzerosInV = sum(subjPerGrp.*subjPerGrp);
            thisRowInds = zeros(totalNonzerosInV,1);
            thisColInds = zeros(totalNonzerosInV,1);
            
            %precompute row and col inds of nonzero idxs in V
            idxOfNonzero = 1;
            for grpIdx = 1:numGrps
                thisGrpInds = find(inGroupFlags(:,grpIdx));

                for sparseRow = 1:length(thisGrpInds)
                    for sparseCol = 1:length(thisGrpInds)
                        thisRowInds(idxOfNonzero) = thisGrpInds(sparseRow);
                        thisColInds(idxOfNonzero) = thisGrpInds(sparseCol);
                        idxOfNonzero = idxOfNonzero+1;
                    end
                end
                    
            end
                
            
            %For each fc edge, build the V and multiply it by
            %pinvDesignMatrix on both sides
            pinvDesignMtx_grp_tpose = pinvDesignMtx_grp';
            for fcIdx = 1:numFcEdges
                
                
                thisSparseVal = residual_grp(thisRowInds, fcIdx).*residual_grp(thisColInds, fcIdx);
                
                sparseV = sparse(thisRowInds, thisColInds, thisSparseVal);
                
                thisBetaCovar = pinvDesignMtx_grp * ...
                                sparseV * ...
                                pinvDesignMtx_grp_tpose;
                
                stdErr(:,fcIdx) = sqrt(diag(thisBetaCovar));
                
            end
            

        end       
        
    end       
   

end