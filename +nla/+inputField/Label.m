classdef Label < nla.inputField.InputField
    properties
        name
        display_name
    end

    properties (Access = protected)
        field = false
    end

    methods
        function obj = Label(name, display_name)
            obj.name = name;
            obj.display_name = display_name;
            obj.satisfied = true;
        end

        function [w, h] = draw(obj, offset_x, offset_y, parent, figure)
            import nla.inputField.LABEL_H nla.inputField.LABEL_GAP

            obj.fig = figure;
            
            if ~isgraphics(obj.field)
                obj.field = uilabel(parent);
            end
            field_width = nla.inputField.widthOfString(obj.display_name, LABEL_H);
            obj.field.Position = [offset_x, offset_y - LABEL_H, field_width, LABEL_H];

            h = LABEL_H;
            w = field_width;
        end

        function undraw(obj)
            if isgraphics(obj.field)
                delete(obj.field);
            end
        end

        function read(obj, ~)
        end

        function [input_struct, false] = store(obj, input_struct)
        end
    end
end