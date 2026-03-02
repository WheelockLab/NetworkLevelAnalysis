classdef MultiContrastResult < matlab.mixin.Copyable
    %Class for holding multiple result objects for multiple named contrasts
    %
    % Builds and accesses a containers.Map object of named objects
    % objects, one per contrast
    
    properties
        contrastNames %cell array of names of each contrast
        contrastResultsMap % containers.Map object that stores each contrast with the key of its name
    end
    
    
    methods
        
        function obj = MultiContrastResult()
            obj.contrastNames = {};
            obj.contrastResultsMap = containers.Map();
        end
        
        function addNamedResult(obj, contrastName, resultObj)
            obj.contrastNames{end+1} = contrastName;
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
            obj.contrastResultsMap = containers.Map();
        end
        
        function outStrArrays = contrastsAsStrings(obj)
            outStrArrays = obj.contrastResultsMap.keys';
        end
        
        function numberOfContrasts = numContrasts(obj)
            numberOfContrasts = obj.contrastResultsMap.Count;
        end
        
        function merge(obj, next_multi_contrast_result)
            %append results from a different multi contrast result to this
            %one
            contrast_names = next_multi_contrast_result.contrastsAsStrings();
            for contrastIdx = 1:length(contrast_names)
                this_contrast_name = contrast_names{contrastIdx};
                this_contrast_results = obj.getNamedResult(this_contrast_name);
                next_contrast_result = next_multi_contrast_result.getNamedResult(this_contrast_name);
                for i = 1:length(this_contrast_results)
                    this_contrast_results{i}.merge(next_contrast_result{i});
                end
                
            end
            
        end
        
    end
    
    
    
    
end