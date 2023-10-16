classdef Legend <  handle
    %LEGEND class used to create and display legend for matrix and trimatrix figures
    properties
        entries = [];
        legend = false;
    end

    properties (Constant)
        Units = 'pixels'
    end

    methods
        function obj = Legend(matrix_object)
            if nargin > 0
                entries = obj.createLegendEntries(matrix_object);
                obj.legend = legend(matrix_object.axes, entries);
                obj = obj.PositionLegend(matrix_object);
                obj.entries = entries;
            end
        end

        function entries = createLegendEntries(obj, matrix_object)
            entries = [];
            for network = 1:matrix_object.number_networks
                entry = bar(matrix_object.axes, NaN);
                entry.FaceColor = matrix_object.networks(network).color;
                entry.DisplayName = matrix_object.networks(network).name;
                entries = [entries entry];
            end
        end

        function obj = positionLegend(obj, matrix_object)
            dimensions = matrix_object.image_dimensions;
            legend_width = obj.legend.Position(3);
            legend_height = obj.legend.Position(4);
            obj.Position = [matrix_object.location_x + dimensions("plot_width") - legend_width - dimensions("offset_x") - legend_offset, matrix_object.location_y + dimensions("plot_height") - legend_height - dimensions("offset_y"), legend_width, legend_height];
        end

    end
end