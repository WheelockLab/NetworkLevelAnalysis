classdef Number < nla.inputField.InputField
    properties
        name
        disp_name
        min
        default
        max
        label = false
        field = false
    end
    
    methods
        function obj = Number(name, disp_name, min, default, max)
            obj.name = name;
            obj.disp_name = disp_name;
            obj.min = min;
            obj.default = default;
            obj.max = max;
            obj.satisfied = true; % a number field always returns a valid input
        end
        
        function [w, h] = draw(obj, x, y, parent, fig)
            
            obj.fig = fig;
            
            h = nla.inputField.LABEL_H;
            label_gap = nla.inputField.LABEL_GAP;
            
            %% Create label
            if ~isgraphics(obj.label)
                obj.label = uilabel(parent);
            end
            obj.label.Text = obj.disp_name;
            label_w = nla.inputField.widthOfString(obj.label.Text, h);
            obj.label.HorizontalAlignment = 'left';
            obj.label.Position = [x, y - h, label_w + label_gap, h];
            
            %% Create spinner
            if ~isgraphics(obj.field)
                obj.field = uieditfield(parent, 'numeric');
            end
            field_w = 50;
            obj.field.Position = [x + label_w + label_gap, y - h, field_w, h];
            obj.field.Limits = [obj.min obj.max];
            obj.field.Value = obj.default;
            
            w = label_w + label_gap + field_w;
        end
        
        function undraw(obj)
            if isgraphics(obj.label)
                delete(obj.label)
            end
            if isgraphics(obj.field)
                delete(obj.field)
            end
        end
        
        function read(obj, input_struct)
            if isfield(input_struct, obj.name)
                obj.field.Value = input_struct.(obj.name);
            else
                obj.field.Value = obj.default;
            end
        end
        
        function [input_struct, error] = store(obj, input_struct)
            input_struct.(obj.name) = obj.field.Value;
            error = false;
        end
    end
end

