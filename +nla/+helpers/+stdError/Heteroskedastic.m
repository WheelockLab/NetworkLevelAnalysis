classdef Heteroskedastic < nla.helpers.stdError.AbstractSwEStdErrStrategy
    
    properties (SetAccess = protected)
        REQUIRES_GROUP = true;
    end

    methods
        
        function contrastStdErr = calculate(obj, sweStdErrInput)

            FORCE_USE_FAST_ALGO = true;
            if FORCE_USE_FAST_ALGO
                %There is a faster, but possibly larger memory
                %implementation of this algorithm. Don't 
                fastAlgoObj = nla.helpers.stdError.Heteroskedastic_FAST();
                contrastStdErr = fastAlgoObj.calculate(sweStdErrInput);
                return;
            end
            
            
            %Calculation of standard error assuming heteroskedascticity
            %consistent errors
            [numCovariates, numObs] = size(sweStdErrInput.pinvDesignMtx);
            
            %give variables shorter names for readability
            pinvDesignMtx = sweStdErrInput.pinvDesignMtx;
            residual = sweStdErrInput.residual;
            
            
            numFcEdges = size(residual,2);
            stdErr = zeros(numCovariates, numFcEdges);
            residSqr = residual.^2;
            correctionFactor = (numObs / (numObs - numCovariates));

            for fcEdgeIdx = 1:numFcEdges

                thisFcEdgeResidSqr = residSqr(:,fcEdgeIdx);
                thisV = diag(thisFcEdgeResidSqr);
                betaCovariance = pinvDesignMtx * thisV * pinvDesignMtx';
                stdErr(:,fcEdgeIdx) = sqrt(correctionFactor * diag(betaCovariance));
                
            end
            
            contrastStdErr = sqrt((sweStdErrInput.contrasts.^2) * (stdErr.^2));

        end
        
    end

end