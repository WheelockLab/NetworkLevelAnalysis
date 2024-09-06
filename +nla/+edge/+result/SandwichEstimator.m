classdef SandwichEstimator < nla.edge.result.Base
    
    properties
        % test result specific properties go here (things that are
        % specific to a particular data input, ie: results of running the sandwich
        % estimator on said data, or covariates which are specific to a
        % particular data set)
        regressCoeffs % numCovariates x numFcElems                             
        
        stdError
        tVals
        pVals
        contrasts 
        contrastCalc
        contrastSE
        contrastTVal
        contrastPVal
    end
    
    methods
        function obj = SandwichEstimator(size, prob_max)
            import nla.* % required due to matlab package system quirks
            
            %MATLAB WEIRDNESS WARNING
            %In parallel processing, this constructor is somehow called
            %with zero arguments, not in any code I've written. Need to be
            %able to get through zero argument case without erroring in
            %order to run in parallel mode. Does not happen in non-parallel
            %mode.
            if nargin ~= 0
                %want to call superclass constructor obj@nla.EdgeLevelResult(size, prob_max);
                %but can't within any "if block" due to MATLABism
                %copying here
                obj.coeff = TriMatrix(size);
                obj.prob = TriMatrix(size);
                obj.prob_sig = TriMatrix(size, 'logical');
                obj.prob_max = prob_max;
                obj.coeff_name = 'contrast t-vals';
            
            end            
            
        end
        
        function output(obj, net_atlas, display_sig)
            import nla.* % required due to matlab package system quirks
            output@nla.edge.result.Base(obj, net_atlas, display_sig);
            
        end
        
        % merged is a function which merges 2 results from the same test
        function merge(obj, results)
            import nla.* % required due to matlab package system quirks
            merge@nla.edge.result.Base(obj, results);
            
            %% TODO Code to merge multiple SandwichEstimatorResults goes here
            % This function is called by TestPool, signature should not
            % change. Results is a vector of other
            % SandwhichEstimatorResults(one per process). This function is
            % called to merge the results of said processes. If you are ex:
            % calculating an average value, you should probably do it here:
            % ex: sum([results.value]) / obj.perm_count would produce the
            % average of 'value'
        end
        
        function setContrasts(obj, newContrasts)
            %force contrasts to be row vector
            if ~any(size(newContrasts)==1)
                error('SandwichEstimatorResults: contrasts must be 1D vector');
            else
                newContrasts = reshape(newContrasts,1,numel(newContrasts));
            end
            
            %check that sizes of contrasts matches size of regression
            %coefficients if they've already been fit
            %if model has already been fit, confirm contrasts is proper
            %size of existing results and modify result values to match new
            %contrast setting
            if ~isempty(obj.regressCoeff)
                %confirm contrasts is proper size
                if length(newContrasts) ~= size(obj.regressCoeffs,1)
                    errMsg = sprintf(['SandwichEstimatorResult: ',...
                                      'size of contrasts does not match number of current fitted regression coefficients',...
                                      '%i contrasts vs %i regression coeffs'],...
                                      length(newContrasts),size(obj.regressCoeffs,1));
                    error(errMsg);
                end
                
                %update existing coeff and prob results with new contrasts
                obj.coeff.v = (newContrasts * obj.regressCoeffs)';
                obj.prob.v = (newContrasts * obj.betaCovarTvals)';
            end
            
            obj.contrasts = newContrasts;               
                
            
        end
        
        
        
    end
end

