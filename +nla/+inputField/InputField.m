classdef InputField < handle
    %INPUTFIELD Base class of input fields
    properties
        satisfied = false % whether the given input field has been satisfied
    end
    
    properties (Access = protected)
        fig
    end
    
    methods (Abstract)
        draw(obj, x, y, parent, fig)
        undraw(obj)
        read(obj, input_struct)
        store(obj, input_struct)
    end
    
    methods
        function loadField(obj, input_struct, field_name)
            if isfield(input_struct, field_name)
                obj.(field_name) = input_struct.(field_name);
            else
                obj.(field_name) = false;
            end
        end
    end
end

