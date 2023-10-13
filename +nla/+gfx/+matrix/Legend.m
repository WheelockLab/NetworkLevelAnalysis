classdef Legend <  matlab.graphics.chartcontainer.mixin.Legend
    %LEGEND class used to create and display legend for matrix and trimatrix figures
    properties
        matrix_object
        axes
        entries = [];
    end

    methods
        function obj = Legend(matrix_object, axes)
            obj.Units = 'pixels'
            if nargin > 0
                obj = obj.createLegendEntries(matrix_object, axes);
                obj = obj.positionLegend(matrix_object);
                obj = legend(axes, obj.entries);
            end
        end

        function obj = createLegendEntries(obj, matrix_object, axes)
            for network = 1:matrix_object.number_networks
                entry = bar(axes, NaN);
                entry.FaceColor = matrix_object.networks(network).color;
                entry.DisplayName = matrix_object.networks(network).color;
                obj.entries = [obj.entries entry];
            end
        end

        function obj = positionLegend(obj, matrix_object)
            dimensions = matrix_object.image_dimensions;
            legend_width = obj.Position(3);
            legend_height = obj.Position(4);
            obj.Position = [matrix_object.location_x + dimensions("plot_width") - legend_width - dimensions("offset_x") - legend_offset, matrix_object.location_y + dimensions("plot_height") - legend_height - dimensions("offset_y"), legend_width, legend_height];
        end


    end
end