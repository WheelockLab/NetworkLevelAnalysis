classdef Button < nla.inputField.InputField

    properties
        name
        display_name
        callback = false
        plot_figure = false
        label = false
        field = false
    end
    
    properties (Constant)
        padding = 12
    end

    methods

        function obj = Button(name, display_name, callback)
            obj.name = name;
            obj.display_name = display_name;
            if nargin == 3
                obj.callback = callback;
            end
        end

        function [width, height] = draw(obj, x_offset, y_offset, parent, plot_figure)

            obj.plot_figure = plot_figure;

            height = nla.inputField.LABEL_H;
            label_width = nla.inputField.widthOfString(obj.display_name, height);
            width = label_width + obj.padding + nla.inputField.LABEL_GAP; % add buffer on each side of text

            if ~isgraphics(obj.field)
                obj.field = uibutton(parent, "Text", obj.display_name);
            end

            if ~isequal(obj.callback, false)
                obj.field.ButtonPushedFcn = obj.callback;
            end
            obj.field.Position = [x_offset, y_offset - height, label_width + obj.padding, height];
        end

        function undraw(obj)
            if isgraphics(obj.field)
                delete(obj.field);
            end
        end

        function read(obj, input_struct)
        end

        function store(obj, input_struct)
        end
    end
end