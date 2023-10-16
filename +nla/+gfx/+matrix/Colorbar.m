classdef Colorbar < matlab.graphics.chartcontainer.mixin.Colorbar
    %COLORBAR Colorbar class for Matrix or TriMatrix figures

    properties
        upper_limit
        lower_limit
        color_map
        Units = 'pixels';
        Location = 'east';
    end

    methods
        function obj = Colorbar(upper_limit, lower_limit, color_map)
            if nargin > 0
                obj.upper_limit = upper_limit;
                obj.lower_limit = lower_limit;
                obj.color_map = color_map;
            end
        end

        function createColorBar(obj, matrix_object)
            if matrix_object.discrete_colorbar
                number_of_ticks = obj.upper_limit - obj.lower_limit;
                display_color_map = matrix_object.color_map(floor((size(matrix_object.color_map, 1) - 1) * [0:number_of_ticks] ./ number_of_ticks) + 1, :);
                display_color_map = repelem(display_color_map, 2, 1);
                display_color_map = display_color_map(2:((number_of_ticks + 1) * 2 - 1), :);
                colormap(obj.axes, display_color_map);
            else
                number_of_ticks = min(size(matrix_object.color_map, 1) - 1, 10);
                colormap(obj.axes, matrix_object.color_map);
            end

            obj = colorbar(obj.axes);
            obj.createColorBarTicks(number_of_ticks)
            obj.setPosition(matrix_object)
            obj.ColorbarVisible = 'on';
        end

        function createColorBarTicks(obj, number_of_ticks)
            ticks = [0:number_of_ticks];
            obj.Ticks = double(ticks) ./ number_of_ticks;

            % tick labels
            tick_labels = {};
            for i = ticks
                tick_labels{i + 1} = sprintf("%.2g", obj.lower_limit + (i * (double(obj.upper_limit - obj.lower_limit) / number_of_ticks)));
            end
            obj.TickLabels = tick_labels;
        end

        function setPosition(obj, matrix_object)
            matrix_dimensions = matrix_object.image_dimensions;
            obj.Position = [obj.Position(1) - matrix_dimensions("offset_x"), obj.Position(2) + matrix_dimnsions("offset_y"), matrix_object.colorbar_width, matrix_dimensions("image_height") - (matrix_dimensions("offset_y") * 2) - 20];
            clim(obj.axes, [0, 1])
        end
    end

end
