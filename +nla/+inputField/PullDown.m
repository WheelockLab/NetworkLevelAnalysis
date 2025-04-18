classdef PullDown < nla.inputField.InputField

    properties
        display_name
        name
        options
        items_data
        plot_figure = false
        label = false
        field = false
        value = false
    end

    properties (Constant)
        ARROW_SIZE = 15 % Size of pulldown arrow
    end

    methods
        function obj = PullDown(name, display_name, options, items_data, value)
            obj.name = name;
            obj.display_name = display_name;
            obj.options = options;
            if nargin >= 4
                obj.items_data = items_data;
            else
                obj.items_data = [];
            end
            if nargin >= 5
                obj.value = value;
            else
                if isempty(obj.items_data)
                    obj.value = obj.options(1);
                else
                    obj.value = obj.items_data(1);
                end
            end
        end

        function [width, height] = draw(obj, x_offset, y_offset, parent, plot_figure)
            import nla.inputField.widthOfString

            obj.plot_figure = plot_figure;

            height = nla.inputField.LABEL_H;
            label_gap = nla.inputField.LABEL_GAP;

            % Label
            if ~isgraphics(obj.label)
                obj.label = uilabel(parent);
            end
            obj.label.Text= obj.display_name;
            label_width = widthOfString(obj.label.Text, height);
            obj.label.HorizontalAlignment = 'left';
            obj.label.Position = [x_offset, y_offset - height, label_width + label_gap, height];
            % pulldown
            if ~isgraphics(obj.field)
                obj.field = uidropdown(parent, "Items", obj.options, "ItemsData", obj.items_data, "Value", obj.value);
            end
            max_string_length = 0;
            max_string = "";
            for option = obj.options
                if widthOfString(option, height) >= max_string_length
                    max_string = option;
                    max_string_length = widthOfString(option, height);
                end
            end
            pulldown_width = widthOfString(max_string, height) + obj.ARROW_SIZE;
            obj.field.Position = [x_offset + label_width + label_gap, y_offset - height, pulldown_width + obj.ARROW_SIZE, height];

            width = label_width + label_gap + pulldown_width + obj.ARROW_SIZE;
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
        end
        
        function store(obj, input_struct)
        end
    end
end