classdef CheckBox < nla.inputField.InputField

    properties
        name
        display_name
        default_value = false
        plot_figure = false
    end

    properties (Access = protected)
        label = false
        field = false
    end

    properties (Constant)
        BOX_WIDTH = 12
    end

    methods

        function obj = CheckBox(name, display_name, default_value)
            if nargin == 2
                obj.name = name;
                obj.display_name = display_name;
            end
            if nargin == 3
                obj.default_value = default_value;
            end
        end

        function [width, height] = draw(obj, x_offset, y_offset, parent, plot_figure)
            import nla.inputField.widthOfString

            obj.plot_figure = plot_figure;
            
            height = nla.inputField.LABEL_H;
            label_width = widthOfString(obj.display_name, height);

            % Checkbox
            if ~isgraphics(obj.field)
                obj.field = uicheckbox(parent, "Text", obj.display_name);
            end
            if obj.default_value
                obj.Value = true;
            end

            obj.field.Position = [x_offset, y_offset, label_width + obj.BOX_WIDTH, height];

            width = label_width + nla.inputField.LABEL_GAP + obj.BOX_WIDTH;
        end

        function undraw(obj)
            if isgraphics(obj.field)
                delete(obj.field)
            end
        end

        function read(obj, test_options)
        end

        function store(obj, test_options)
        end
    end
end