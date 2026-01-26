classdef MultiContrast < nla.edge.result.Base
    
    properties
        contrastNames %cell array of names of each contrast
        contrastValues % m x p matrix. Each row is the vector of values for one contrast
        contrastResultsMap % containers.Map object that stores each contrast with the key of its name
    end
    
    
    methods
        
        function obj = MultiContrast()
            obj.contrastNames = {};
            obj.contrastValues = [];
            obj.contrastResultsMap = containers.Map();
        end
        
        function addNamedResult(obj, contrastName, resultObj)
            obj.contrastNames{end+1} = contrastName;
            if isempty(obj.contrastValues)
                obj.contrastValues = resultObj.contrasts;
            else
                obj.contrastValues(end+1,:) = resultObj.contrasts;
            end
            obj.contrastResultsMap(contrastName) = resultObj;
        end
        
        function resultObj = getNamedResult(obj, contrastName)
            if obj.contrastResultsMap.isKey(contrastName)
                resultObj = obj.contrastResultsMap(contrastName);
            else
                resultObj = [];
            end
        end
        
        function clearResults(obj)
            obj.contrastNames = {};
            obj.contrastValues = [];
            obj.contrastResultsMap = containers.Map();
        end
        
        function outStrArrays = contrastsAsStrings(obj)
            outStrArrays = obj.contrastResultsMap.keys';
        end
        
        function numberOfContrasts = numContrasts(obj)
            numberOfContrasts = obj.contrastResultsMap.Count;
        end
        
    end
    
    
    
    
end