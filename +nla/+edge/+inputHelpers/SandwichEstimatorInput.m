classdef SandwichEstimatorInput < handle
    % used to pass object by reference to SandwichEstimatorInputGUI and
    % receive output settings from that GUI
    %
    % call 'struct' function on an instance of this class to get an
    % equivalent struct
    properties
        groupId %n x 1 vector
        permute_method = nla.edge.permutationMethods.FCWildBootstrap();
        stdErrCalcObj %implements nla.helpers.stdError.AbstractSwEStdErrStrategy()
        behavior % nx1 vector (combine into covariates/variables)
        covariates % nxp matrix
        contrasts % c x (p+1) matrix
        contrastNames % c x 1 cell of strings of names
        FORCE_ORDINARY_LEAST_SQUARES = false
    end 
    
    
    methods
        function outStruct = pushFieldsIntoStruct(obj, inStruct)
            outStruct = inStruct;
            
            classProps = properties(obj);
            
            for iProp = 1:length(classProps)
                thisPropName = classProps{iProp};
                
                outStruct.(thisPropName) = obj.(thisPropName);
            end
            
        end
        
        function loadFieldsFromStruct(obj, inStruct)
            classProps = properties(obj);
            
            for iProp = 1:length(classProps)
                thisPropName = classProps{iProp};
                
                if isfield(inStruct, thisPropName)
                    obj.(thisPropName) = inStruct.(thisPropName);
                end
            end
        end
        
        function isValid = isValid(obj)
            isValid = true;
            
            groupRows = size(obj.groupId,1);
            [covarRows, covarCols] = size(obj.covariates);
            [contrastRows, contrastCols] = size(obj.contrasts);
            
            if any([covarCols, contrastCols] ~= covarCols)
                isValid = false;
            end
            if obj.stdErrCalcObj.REQUIRES_GROUP && groupRows==0
                isValid = false;
            end
            
            if contrastCols<=0
                isValid = false;
            end
            
        end
        
        function set.FORCE_ORDINARY_LEAST_SQUARES(obj, forceOLS)
            if forceOLS
                obj.stdErrCalcObj = nla.helpers.stdError.Homoskedastic();
            end
            obj.FORCE_ORDINARY_LEAST_SQUARES = forceOLS;
        end
    end
    
end