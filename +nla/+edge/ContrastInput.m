classdef ContrastInput < handle & matlab.mixin.Copyable
    
    properties
        dataTable = [];
        name = '';
        contrastVector = [];        
    end
    
    methods
        function isValidFlag = isValid(obj)
            if any(~isspace(obj.name))
                isValidFlag = true;
            else
                isValidFlag = false;
            end
        end
        
        function str = asDetailedString(obj)        
            str = sprintf('%s (%s)',obj.name, obj.contrastVectorAsString());
        end
        
        function str = contrastVectorAsString(obj)
            str = num2str(obj.contrastVector);
            str = regexprep(str, '\s+', ' ');
        end
    end
    
    
    
        
    
end