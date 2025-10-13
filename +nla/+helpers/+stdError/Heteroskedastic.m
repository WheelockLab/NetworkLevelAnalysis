classdef Heteroskedastic < nla.helpers.stdError.AbstractSwEStdErrStrategy
    
    properties (SetAccess = protected)
        REQUIRES_GROUP = true;
    end

    methods
        
        function stdErr = calculate(obj, sweStdErrInput)
            
            validateattributes(sweStdErrInput, 'nlaEckDev.sweStdError.SwEStdErrorInput', {});
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

        end
        
    end

end