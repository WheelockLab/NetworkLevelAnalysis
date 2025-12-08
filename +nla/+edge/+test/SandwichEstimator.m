classdef SandwichEstimator < nla.edge.BaseTest
    %SANDWICHESTIMATOR Summary of this class goes here
    %   Detailed explanation goes here
    properties
        name = "Sandwich Estimator"
        coeff_name = 'SwE Contrast T-value'
    end
    
    properties
        % test specific properties go here (things that will persist
        % over multiple runs) + aren't specific to a given data set)
        
        nonpermRegressCoeffs
        nonpermResiduals
    end
    
    methods
        function obj = SandwichEstimator()
            obj@nla.edge.BaseTest();            
            
        end
        
        function result = run(obj, input_struct)
            
            sweInput = obj.sweInputObjFromStruct(input_struct);
            
            if ~isfield(input_struct, 'fit_intercept') | input_struct.fit_intercept
                sweInput = obj.addInterceptCovariateToInputIfNone(sweInput); %Forces model to include fitting an intercept term. Adds column to covariates and contrasts                
            end    
            
            numContrasts = size(sweInput.contrasts,1);
            if  numContrasts == 1
                result = obj.fitModel(sweInput);                
            else
                result = cell(numContrasts,1);
                for i = 1:numContrasts
                    thisInput = sweInput;
                    thisInput.contrasts = sweInput.contrasts(i,:);
                    result{i} = obj.fitModel(thisInput);
                end
            end
            
            
        end
        
        
    end
    
    
    methods (Access = private)
        
        
        function sweInputStruct = sweInputObjFromStruct(obj, input_struct)
            
            sweInputStruct = struct();
            
            % build scanMetadata object from inputs
            %scanMetadata = nlaEckDev.swedata.ScanMetadata();
            if isfield(input_struct, 'subjId')
                sweInputStruct.subjId = input_struct.subjId;
            else
                numObs = size(input_struct.covariates,1);
                sweInputStruct.subjId = (1:numObs)';
            end
            
            if isfield(input_struct, 'groupId')
                sweInputStruct.groupId = input_struct.groupId;
            else
                sweInputStruct.groupId = ones(length(input_struct.subjId),1);
            end
            
            if isfield(input_struct, 'visitId')
                sweInputStruct.visitId = input_struct.visitId;
            else
                sweInputStruct.visitId = ones(length(sweInputStruct.subjId),1);
            end
            
            sweInputStruct.fcData = input_struct.func_conn.v';
            if isfield(input_struct, 'behavior') & (input_struct.behavior ~= 0)
                sweInputStruct.covariates = [input_struct.behavior, input_struct.covariates];
            else
                sweInputStruct.covariates = input_struct.covariates;
            end
            %sweInput.scanMetadata = scanMetadata;
            sweInputStruct.prob_max = input_struct.prob_max;
            sweInputStruct.contrasts = input_struct.contrasts;
            
            if isfield(input_struct, 'stdErrCalcObj')
                sweInputStruct.stdErrCalcObj = input_struct.stdErrCalcObj; %How will this really be passed in?
            else
                sweInputStruct.stdErrCalcObj = nlaEckDev.sweStdError.UnconstrainedBlocks();
            end
            
            if isfield(input_struct, 'fit_intercept')
                sweInputStruct.fit_intercept = input_struct.fit_intercept;
            end
            
        end
        
        function sweInput = addInterceptCovariateToInputIfNone(obj, sweInput)
            
            
            columnIsAllSameValue = ~any(diff(sweInput.covariates,1),1);
            if ~any(columnIsAllSameValue)
                %If no column in covariates is currently all same value,
                %add a column so that an intercept term is fit by the
                %linear model
                numObs = size(sweInput.covariates,1);
                sweInput.covariates = [sweInput.covariates, ones(numObs,1)];
                sweInput.contrasts = [sweInput.contrasts, 0];
                
            end
                
            
            
        end
        
        
        function sweRes = fitModel(obj, input)
                    
                        
            numFcEdges = size(input.fcData,2);
            
            %the data for each scan in fcData (ie each row) represents the
            %flattened lower triangle of fc data. Use the number of fc
            %edges represented to compute the size of the original
            %non-flattened matrix, which is needed to construct a result
            %object
            fcMatSize = (1 + sqrt(1 + 4*(numFcEdges*2))) / 2;
            
            sweRes = nla.edge.result.SandwichEstimator(fcMatSize, input.prob_max);
            
            designMtx = input.covariates;
            %designMtx = obj.zeroMeanUnitVarianceByColumn(designMtx); %Make covariates zero mean unit variance
                               
            [regressCoeffs, residual] = obj.fitLinearModel(input.fcData, designMtx);
                        
            
            %Build input and pass to one of several methods for calculating
            %standard error
            %TODO: Should this calculate beta covariance instead?
            
            stdErrCalcObj = input.stdErrCalcObj;
            %stdErrCalcObj = nlaEckDev.sweStdError.Guillaume(); %If you want to hard code the std err calc object
            
            stdErrInput = struct();% nlaEckDev.sweStdError.SwEStdErrorInput();
            scanMetadata = struct();
            scanMetadata.subjId = input.subjId; % vec [numScans]
            scanMetadata.groupId = input.groupId;%groupId; % vec [numScans]        
            scanMetadata.visitId = input.visitId; % vec [numScans] 
            
            stdErrInput.scanMetadata = scanMetadata;
            stdErrInput.residual = residual;
            stdErrInput.pinvDesignMtx = pinv(designMtx);
            
            %sweRes.stdError = stdErrCalcObj.calculate(stdErrInput);
            stdError = stdErrCalcObj.calculate(stdErrInput);
            
            
            contrastCalc = input.contrasts * regressCoeffs;
            contrastSE = sqrt((input.contrasts.^2) * (stdError.^2));
            
            dof = obj.calcDegreesOfFreedom(designMtx);
            
            %tVals = regressCoeffs ./ stdError;
            contrastTVal = contrastCalc ./ contrastSE;
            
            %pVals = zeros(size(tVals));  
            contrastPVal = 2*(1-cdf('T',abs(contrastTVal),dof));
                
            %sweRes.tVals = tVals;
            %sweRes.pVals = pVals;
            %sweRes.regressCoeffs = regressCoeffs;             
            sweRes.coeff.v = contrastTVal';
            sweRes.prob.v = contrastPVal';
            sweRes.prob_sig.v = (sweRes.prob.v < input.prob_max);            
            sweRes.avg_prob_sig = sum(sweRes.prob_sig.v) ./ numel(sweRes.prob_sig.v);
            sweRes.contrasts = input.contrasts;
            
            %Change expected coefficient range to be more accurate to Sandwich
            %Estimator ranges
            sweRes.coeff_range = [-3 3];
            
        end
        
        
        function outResidual = calcResidual(obj, X, pInvX, Y)
            
            hat = X * pInvX;
            
            residCorrectFactor = (1 - diag(hat)).^(-1); %Type 3 residual correction defined in Guillaume 2014
            
            %compute residuals
            
            % Goal is to multiply row for each subject by respective
            % correction factor in vector residCorrectFactor.
            % Below equation is equivalent to row wise multiplying Y-hat*Y
            % with elements of residCorrectFactor.
            % It is exactly equivalent to:
            %    outResidual = diag(residCorrectFactor) * (Y - hat*Y);
            % but over twice as fast by avoiding constructing sparse
            % [subjxsubj] matrix of diag(residCorrectFactor)   
            
            %outResidual = diag(residCorrectFactor) * (Y - hat*Y);
            outResidual = residCorrectFactor .* (Y - hat*Y);

            
        end
       
        function outMtx = zeroMeanUnitVarianceByColumn(obj, inMtx)
            
            outMtx = zeros(size(inMtx));
            
            for colIdx = 1:size(inMtx,2)
                
                colMean = mean(inMtx(:,colIdx));
                colStd = std(inMtx(:,colIdx));
                if colStd ~=0
                    outMtx(:,colIdx) = (inMtx(:,colIdx) - colMean) / colStd;
                else
                    %If all values of column are same, do not change them
                    %TODO: handle this here??? or somewhere else?
                    %TODO: set to zeros? ones? orig values?
                    outMtx(:,colIdx) = inMtx(:,colIdx);
                end
                
            end
            
        end
        
        function degOfFree = calcDegreesOfFreedom(obj, designMtx)
            
            degOfFree = size(designMtx,1) - size(designMtx,2) - 1;
            
        end
        
        function [regressCoeffs, residual] = fitLinearModel(obj, fcData, designMtx)
            
            pinvDesignMtx = pinv(designMtx);
            regressCoeffs = pinvDesignMtx * fcData;            
            residual = obj.calcResidual(designMtx, pinvDesignMtx, fcData);
            
        end        
        
        
        
    end % end private methods
    
    methods (Static)
        function inputs = requiredInputs()
            inputs = {nla.inputField.Number('prob_max', 'Edge-level P threshold <', 0, 0.05, 1),...
                nla.inputField.NetworkAtlasFuncConn(), nla.inputField.SandwichEstimator()};
        end
    end
end

