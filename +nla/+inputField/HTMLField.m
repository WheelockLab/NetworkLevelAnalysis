classdef HTMLField < nla.inputField.InputField

    properties
        name
        display_name
        field = false
    end

    methods

        function obj = HTMLField(name, display_name)
            obj.name = name;
            obj.display_name = display_name;
        end

        function [width, height] = draw(obj, x_offset, y_offset, parent, plot_figure)

            obj.plot_figure = plot_figure;

            height = nla.inputField.LABEL_H;

            if ~isgraphics(obj.field)
                obj.field = uihtml(parent);
                obj.parseHTML();
                obj.field.Position(1) = x_offset; 
                obj.field.Position(2) = y_offset - height
                obj.field.Position(4) = height;
            end
        end

        function undraw(obj)
            if isgraphics(obj.field)
                delete(obj.field)
            end
        end

        function read(obj, input_struct)
        end

        function store(obj, input_struct)
        end
    end

    methods (Access = private)
        function html_text = parseHTML(obj)
            html_tree = htmlTree(obj.html);
            html_text = extractHTMLText(html_tree);
            width = nla.inputField.widthOfString(html_text, nla.inputField.LABEL_H);
            obj.field.Position(3) = width + nla.inputField.LABEL_GAP;
        end

        function callback(obj)
            obj.parseHTML();
        end
    end
end