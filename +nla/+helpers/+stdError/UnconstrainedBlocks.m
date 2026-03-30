classdef UnconstrainedBlocks < nla.helpers.stdError.AbstractSwEStdErrStrategy

    properties (SetAccess = protected)
        REQUIRES_GROUP = true;
    end
    
    methods
        
        function contrastStdErr = calculate(obj, sweStdErrInput)            
            
            
            %rename variables for readability
            pinvDesignMtx = sweStdErrInput.pinvDesignMtx;
            residual = sweStdErrInput.residual;
            groupIds = sweStdErrInput.scanMetadata.groupId;
            unqGrps = unique(groupIds);
            
            obj.throwErrorIfVEntirelyFull(unqGrps);
            
            [numCovariates, ~] = size(pinvDesignMtx);
            [numObs, numFcEdges] = size(residual);
            
            stdErr = zeros(numCovariates, numFcEdges);
            
            numNonzeroValuesInContrast = sum(sweStdErrInput.contrasts~=0);
            if numNonzeroValuesInContrast > 1
                WALD_TEST = true;
            else
                WALD_TEST = false;
            end
            
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
            %elements and multiplying by the one non-zero value of the
            %contrast

            if ~WALD_TEST
                for grpIdx = 1:length(unqGrps)
                    thisGrpId = unqGrps(grpIdx);
                    subjThisGrp = groupIds == thisGrpId;
                    halfSandwich = pinvDesignMtx(:, subjThisGrp) * residual(subjThisGrp,:);

                    covB = covB + halfSandwich .* halfSandwich;

                end

                stdErr(:) = sqrt(covB);
                contrastStdErr = sqrt((sweStdErrInput.contrasts.^2) * (stdErr.^2));
            else     
                for grpIdx = 1:length(unqGrps)

                    thisGrpId = unqGrps(grpIdx);
                    subjThisGrp = groupIds == thisGrpId;
                    halfSandwich = pinvDesignMtx(:, subjThisGrp) * residual(subjThisGrp,:);
                    
                    for fcEdgeIdx = 1:numFcEdges
                        covB(:,:,fcEdgeIdx) = covB(:,:,fcEdgeIdx) + ...
                                                (halfSandwich(:,fcEdgeIdx) * halfSandwich(:,fcEdgeIdx)');
                    end
                end

                %Computation of contrast StdErr here
                contrasts = sweStdErrInput.contrasts;
                contrastStdErr = zeros(1,numFcEdges);
                for fcEdgeIdx = 1:numFcEdges
                    contrastStdErr(fcEdgeIdx) = contrasts * covB(:,:,fcEdgeIdx) * contrasts';
                end

            end  

        end
        
    end

    methods (Access = protected)

        function throwErrorIfVEntirelyFull(obj, uniqueGroupIds)
            %If V is entirely full, throw an error
            if length(uniqueGroupIds) == 1
                
                error(['Standard Error Calculation must include some contraints on error covariance.\n',...
                    'If only one group is in data passed to UnconstrainedBlock calculator, covariance of beta reduces to zero.',...
                    ' Fix by either separating data into different group IDs, or using a different standard error calculator strategy',...
                    ' (Homoskedastic, Heteroskedastic, etc)\n\n']);
                
            end            
            
        end

    end



end