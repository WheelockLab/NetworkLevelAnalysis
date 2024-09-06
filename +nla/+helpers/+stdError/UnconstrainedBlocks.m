classdef UnconstrainedBlocks < nla.helpers.stdError.AbstractSwEStdErrStrategy

    properties
        
        SPARSITY_THRESHOLD = 0.2;
        
    end
    
    methods
        
        function stdErr = calculate(obj, sweStdErrInput)
            %Computes Standard Error assuming unconstrained blocks
            %Uses standard matrix multiplication to compute standard error,
            %since it does not make assumption that V is sparse.
                        
            groupIds = sweStdErrInput.scanMetadata.groupId;
            unqGrps = unique(groupIds);
            
            obj.throwErrorIfVEntirelyFull(unqGrps);
            
            vSparsity = obj.computeVSparsity(groupIds);
            
            %Ben Kay 'Half Sandwich' algorithm seems to be at least as good
            %or better than any of the other clever approaches so far.
            %Might be able to beat it by using the clever approach and only
            %computing the diagonal of covBat
            FORCE_HALF_SW_ALGO = true;
            
            if FORCE_HALF_SW_ALGO
                stdErrStrategy = nlaEckDev.sweStdError.UnconstrainedBlocks_BenKay();            
            elseif vSparsity <= obj.SPARSITY_THRESHOLD
                stdErrStrategy = nlaEckDev.sweStdError.UnconstrainedBlocks_Sparse();
            else
                stdErrStrategy = nlaEckDev.sweStdError.UnconstrainedBlocks_Dense();
            end
            
            stdErr = stdErrStrategy.calculate(sweStdErrInput);
            
            
        end
        
        
        
    end
    
    methods (Access = protected)        
        
        function fractionNonZero = computeVSparsity(obj, groupIds)
            %Do quick check of how many elements of V we expect to be
            %nonzero given the group Ids of our observations.
            %This calculation will only be fast if V is sparse, so we
            %should determine how full V will be and warn user if this
            %method will be slow.
            unqGrps = unique(groupIds);
            countInGrps = histcounts(groupIds,[unqGrps;Inf]);
            
            numNonzeroElems = sum(countInGrps.^2);
            totalElems = length(groupIds)*length(groupIds);
            
            fractionNonZero = numNonzeroElems / totalElems;
            
        end
        
        function throwErrorIfVEntirelyFull(obj, uniqueGroupIds)
            %If V is entirely full, throw an error
            if length(uniqueGroupIds) == 1
                
                error(['Standard Error Calculation must include some contraints on error covariance.\n',...
                    'If only one group is in data passed to UnconstrainedBlock calculator, covariance of beta reduces to zero.',...
                    ' Fix by either separating data into different group IDs, or using a different standard error calculator strategy',...
                    ' (Homoskedastic, Heteroskedastic, etc)\n\n']);
                
            end            
            
        end
        
        function [groupedPinv, groupedResidual, groupIds] = reorderDataByGroup(obj, origPinvDesignMtx, origResidual, origGrps)
            
            [numCovariates, ~] = size(origPinvDesignMtx);
            
            %Group all data in one matrix and sort by group
            %NOTE: need to use transpose of pinvDesignMatrix!!!
            allData = [origGrps, origPinvDesignMtx', origResidual];
            sortedData= sortrows(allData,1);
            
            pinvColRange = 2:(numCovariates+1);
            residualColRange = (numCovariates+2):(size(allData,2));
            
            groupedPinvTpose = sortedData(:,pinvColRange);
            groupedPinv = groupedPinvTpose';
            groupedResidual = sortedData(:,residualColRange);
            groupIds = sortedData(:,1);
            
        end
        
        
        
    end
    
   

end