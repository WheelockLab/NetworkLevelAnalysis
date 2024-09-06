classdef UnconstrainedBlocks_BenKay < nla.helpers.stdError.UnconstrainedBlocks
    
    methods
        
        function stdErr = calculate(obj, sweStdErrInput)            
            
            
            %rename variables for readability
            pinvDesignMtx = sweStdErrInput.pinvDesignMtx;
            residual = sweStdErrInput.residual;
            groupIds = sweStdErrInput.scanMetadata.groupId;
            unqGrps = unique(groupIds);
            
            obj.throwErrorIfVEntirelyFull(unqGrps);
            
            [numCovariates, ~] = size(pinvDesignMtx);
            [numObs, numFcEdges] = size(residual);
            
            stdErr = zeros(numCovariates, numFcEdges);
            
            WALD_TEST = false;
            
            if ~WALD_TEST
                covB = zeros(numCovariates,numFcEdges);
            else            
                covB = zeros(numCovariates,numCovariates,numFcEdges);
            end
            
            %NOTE, optimized from swe_block.m from Benjamin Kay
            %if NOT WALD_TEST, can just compute diagonals of cov(B), which
            %makes the original halfsandwich of
            %pinvDesignMtx(:,subjThisGrp) * residual(subjThisGrp, fcIdx)
            %into a [numCovars x 1] matrix, and then squaring for the 
            
            
            for grpIdx = 1:length(unqGrps)
                
                thisGrpId = unqGrps(grpIdx);
                subjThisGrp = groupIds == thisGrpId;
                halfSandwich = pinvDesignMtx(:, subjThisGrp) * residual(subjThisGrp,:);
                
                if WALD_TEST
                    
                    for fcEdgeIdx = 1:numFcEdges
                        covB(:,:,fcEdgeIdx) = covB(:,:,fcEdgeIdx) + ...
                                                (halfSandwich(:,fcEdgeIdx) * halfSandwich(:,fcEdgeIdx)');
                    end
                    
                else    

                    covB = covB + halfSandwich .* halfSandwich;

                end

            end            
            
            
            if WALD_TEST
                waldRunTime = toc
                stdErr = rand(numCovariates, numFcEdges);
                error('Not Implemented!');
            else
                stdErr(:) = sqrt(covB);
            end
            

        end
        
    end

end