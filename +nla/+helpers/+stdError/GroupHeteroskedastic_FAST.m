classdef GroupHeteroskedastic_FAST < nla.helpers.stdError.AbstractSwEStdErrStrategy

    methods
        
        function stdErr = calculate(obj, sweStdErrInput)
            %Computes Standard Error, but accelerated using assumption of
            %heteroskeadisticity between groups for quicker computation
            %
            %To understand what is meant by 'heteroskedasticity' here in computation of covariance of betas, 
            %refer to https://lukesonnet.com/teaching/inference/200d_standard_errors.pdf
            %
            %Our covariance of betas is of form M * V * M', and with
            %heteroskedasticity assumption, V is diagonal. With this
            %assumption, can greatly accelerate computation. 
            %Efficient algo adapted from
            %https://www.mathworks.com/matlabcentral/answers/87629-efficiently-multiplying-diagonal-and-general-matrices
            %(And in case that page goes away, copying text in file
            %/data/wheelock/data1/people/ecka/fastDiagMatrixMultAlgo.txt)
            
            
            %rename variables for readability
            pinvDesignMtx = sweStdErrInput.pinvDesignMtx;
            residual = sweStdErrInput.residual;
            
            %Calculation of standard error assuming heteroskedascticity
            %consistent errors
            [numCovariates, numObs] = size(pinvDesignMtx);
            
            
            invDesMtxSelfMultPreCompute = zeros(numCovariates,numCovariates,numObs);

            for i = 1:numObs
                invDesMtxSelfMultPreCompute(:,:,i) = pinvDesignMtx(:,i) * pinvDesignMtx(:,i)';
            end
            invDesMtxSelfMultPreCompute = reshape(invDesMtxSelfMultPreCompute,numCovariates^2, numObs);
            
            %Use pregenerated matrix to compute covariance of our estimates
            %of the regressors. 
            %
            %TODO: correction factor here is 'HC1' (default used in stata), but
            %HC2 or HC3 might be preferable? (per
            %lukesonnet.com/teaching/inference/200d_standard_errors.pdf)
            correctionFactor = (numObs / (numObs - numCovariates));
            
            %compute covariance of each group
            groupedVariance = zeros(size(residual));
            unqGrps = unique(sweStdErrInput.scanMetadata.groupId);
            
            for grpIdx = 1:length(unqGrps)
                thisGrpId = unqGrps(grpIdx);
                rowsThisGrp = sweStdErrInput.scanMetadata.groupId == thisGrpId;
                obsThisGrp = sum(rowsThisGrp);
                
                pooledVarianceThisGrp = correctionFactor * ones(obsThisGrp,1) * sum(residual(rowsThisGrp,:).^2,1)/obsThisGrp;
                groupedVariance(rowsThisGrp,:) = pooledVarianceThisGrp;
            end
            
            betaCovarianceFlat = (invDesMtxSelfMultPreCompute * groupedVariance);
            
            %Get square root of diagonal elements to compute std error
            diagElemIdxsInFlatArr = 1:(numCovariates+1):numCovariates^2;            
            stdErr = sqrt(betaCovarianceFlat(diagElemIdxsInFlatArr,:));

        end
        
    end
    
   

end