classdef MatrixPlot < handle
    %MATRIXPLOT Base class for drawing a matrix or tri-matrix organized in
    % networks

    properties
        matrix % matrix data to plot, either full matrix or tri-matrix data
        networks % Vector of objects which must implement IndexGroup, ie:
        % have a name, color, and a vector of indices corresponding to
        % data in the input matrix
        figure % figure to plot in
        x_position
        y_position
        lower_limit % lower limit of scale
        upper_limit % upper limit of scale
        name % name of the plot
        draw_legend = true
        draw_colorbar = true
        color_map = turbo(256) % default color map
        marked_networks = false % networks to mark with a symbol
        discrete_colorbar = true % colorbar as discrete (or continuous)
        network_clicked_callback = true % button to add to network to click for callback
        figure_size = nla.gfx.FigSize.SMALL
        figure_margins = nla.gfx.FigMargins.WHITESPACE
        network_dimensions = []
        axes = false
        image_display = false
        matrix_type = nla.gfx.MatrixType.MATRIX
    end

    properties (Dependent)
        number_networks
        network_matrix
        image_dimensions
        as_matrix
    end

    properties (Access = private, Constant)
        colorbar_width = 25;
        colorbar_offset = 15;
        colorbar_text_w = 50;
        legend_offset = 5;
    end

    methods

        function obj = MatrixPlot(matrix, networks, figure, x_position, y_position, lower_limit, upper_limit, name, figure_size)
            if nargin > 0
                if isequal(class(matrix), 'nla.TriMatrix') 
                    if ~isnumeric(matrix.v)
                        % If this doesn't work (ie: program errors here), your data is
                        % not of a numeric type, and cannot be converted to a numeric
                        % type, which means it cannot be displayed.
                        matrix.v = single(matrix.v);
                    end
                    obj.matrix_type = nla.gfx.MatrixType.TRIMATRIX;
                end
                obj.matrix = matrix;
                obj.networks = networks;
                obj.figure = figure;
                obj.figure.Renderer = 'painters';
                obj.x_position = x_position;
                obj.y_position = y_position;
                obj.lower_limit = lower_limit;
                obj.upper_limit = upper_limit;
                obj.name = name;
                obj.figure_size = figure_size;
            end

        end

        function displayImage(obj)
            % dependent props we're calling only once instead of many
            dimensions = obj.image_dimensions;
            number_of_networks = obj.number_networks;
            obj.network_dimensions = zeros(number_of_networks, number_of_networks, 4);

            % draw axes
            obj = obj.drawAxes(obj.figure, obj.x_position, obj.y_position, dimensions("image_width"), dimensions("image_height"));

            % initialization of the data that's going to become the image 
            image_data = NaN(dimensions("image_height"), dimensions("image_width"), 3);
            obj.image_display = image(obj.axes, image_data, 'XData', [1 obj.axes.Position(3)], 'YData', [1 obj.axes.Position(4)]);

            % add callback for clicking on image
            obj.addCallback(obj.image_display);

            % set limit on axes
            obj.axes.XLim = [0 obj.image_display.XData(2)];
            obj.axes.YLim = [0 obj.image_display.YData(2) + 1];

            obj = obj.embiggenMatrix();

            % Makes NaNs transparent
            obj.image_display.AlphaData = ~isnan(obj.image_display.CData(:,:,1));
            refreshdata(obj.figure)
        end

        % getters for dependent properties
        function value = get.number_networks(obj)
            value = numel(obj.networks);
        end

        function value = get.network_matrix(obj)
            value = (size(obj.as_matrix, 1) == obj.number_networks);
        end

        function value = get.image_dimensions(obj)
            % thickness of network label
            label_size = 13;

            if obj.figure_size == nla.gfx.FigSize.LARGE
                label_size = 20;
            end

            % display dimensions calculations
            display_matrix_size = 0;
            if obj.network_matrix
                display_matrix_size = obj.number_networks;
            else

                for x = 1:numel(obj.networks)
                    display_matrix_size = display_matrix_size + obj.networks(x).numROIs();
                end

            end

            image_height = (display_matrix_size * obj.elementSize()) + obj.number_networks + label_size + 2;
            image_width = image_height;

            if ~obj.network_matrix
                image_width = image_width - 1;
            end

            % image margins
            offset_x = 0;
            offset_y = 0;

            if obj.figure_margins == nla.gfx.FigMargins.WHITESPACE
                offset_x = 50;
                offset_y = 50;
                image_width = image_width + (offset_x * 2);
                image_height = image_height + (offset_y * 2);
            end

            plot_width = image_width;
            plot_height = image_height;

            if ~isempty(obj.name)
                image_height = image_height + 20;
            end

            % colorbar margins
            if obj.draw_colorbar
                image_width = image_width + obj.colorbar_width + obj.colorbar_offset + obj.colorbar_text_w;
            end

            dimensions = [image_height image_width offset_x offset_y plot_width plot_height display_matrix_size label_size];
            value = containers.Map(["image_height" "image_width" "offset_x" "offset_y" "plot_width" "plot_height" "display_matrix_size" "label_size"], dimensions);
        end

        function value = get.as_matrix(obj)
            value = obj.matrix.asMatrix();
        end
    end

    methods (Static)

        function clickCallback(~, ~, obj)

            if ~isequal(obj.network_clicked_callback, false)
                % get point clicked
                coordinates = get(obj.axes, 'CurrentPoint');
                coordinates = coordinates(1, 1:2);

                % find network membership
                for y_iterator = 1:obj.number_networks

                    for x_iterator = 1:y_iterator
                        net_coordinates = obj.network_dimensions(x_iterator, y_iterator, :);
                        click_padding = 1;

                        if (coordinates(1) >= net_coordinates(1) - click_padding) && ...
                                (coordinates(1) <= net_coordinates(2) + click_padding) ...
                                && (coordinates(2) >= net_coordinates(3) - click_padding) ...
                                && (coordinates(2) <= net_coordinates(4) + click_padding)
                            obj.network_clicked_callback(y_iterator, x_iterator);
                        end

                    end

                end

            end

        end

    end

    methods (Access = protected)

        function element_size = elementSize(obj)
            element_size = 1;

            if obj.network_matrix
                element_size = floor(325 / obj.number_networks);
                if obj.figure_size == nla.gfx.FigSize.LARGE
                    element_size = floor(500 / obj.number_networks); 
                end

            else

                if obj.figure_size == nla.gfx.FigSize.LARGE

                    if size(obj.as_matrix, 1) <= 500
                        element_size = 2;
                    end

                end

            end

        end

        function obj = drawAxes(obj, fig, location_x, location_y, image_width, image_height)
            obj.axes = uiaxes(fig, 'Position', [location_x, location_y, image_width, image_height]);
            axis(obj.axes, 'image');
            obj.axes.XAxis.TickLabels = {};
            obj.axes.YAxis.TickLabels = {};
        end

        function addCallback(obj, x)

            if ~isequal(obj.network_clicked_callback, false)
                x.ButtonDownFcn = {@obj.clickCallback, obj};
            end

        end

        function obj = embiggenMatrix(obj)
            import nla.gfx.colorChunk nla.gfx.MatrixType nla.gfx.valToColor nla.gfx.drawLine
            number_of_networks = obj.number_networks;
            dimensions = obj.image_dimensions;
            network_matrix = obj.network_matrix;
            matrix_as_matrix = obj.as_matrix;

            bigger_image_display = obj.image_display.CData;

            position_y = dimensions("offset_y") + 2;
            if ~isempty(obj.name)
                position_y = position_y + 20;
            end

            for network = 1:number_of_networks
                network_indexes = network;
                if ~network_matrix
                    network_in_bound = obj.networks(network).indexes <= size(matrix_as_matrix, 1);
                    network_indexes = obj.networks(network).indexes(network_in_bound);
                end

                chunk_height = numel(network_indexes) * obj.elementSize();
                
                % Left side of matrix color bars
                top = position_y;
                bottom = position_y + chunk_height;
                left = dimensions("offset_x") + 2;
                right = dimensions("offset_x") + dimensions("label_size") + 1;
                bigger_image_display(top:bottom, left:right+1, :) = colorChunk(obj.networks(network).color, chunk_height + 1, dimensions("label_size") + 1);
                obj = obj.drawLeftLinesOnLabels(top, bottom, left, right);

                position_x = dimensions("label_size") + dimensions("offset_x") + 3;
                maximum_x = number_of_networks;
                if obj.matrix_type == MatrixType.TRIMATRIX
                    maximum_x = network;
                end

                for x = 1:maximum_x
                    x_index = x;
                    if ~network_matrix
                        x_in_bound = obj.networks(x).indexes < size(matrix_as_matrix, 1);
                        x_indexes = obj.networks(x).indexes(x_in_bound);
                    end

                    chunk_width = numel(x_indexes) * obj.elementSize();

                    % Fill the chunk with a color mapped to its value
                    chunk_raw = matrix_as_matrix(network_indexes, x_indexes);
                    chunk = valToColor(chunk_raw, obj.lower_limit, obj.upper_limit, obj.color_map);
                    chunk(isnan(chunk_raw)) = NaN; % puts all NaNs back removed with valToColor

                    bigger_image_display(position_y:position_y + chunk_height - 1, position_x:position_x + chunk_width - 1, :) = repelem(chunk, obj.elementSize(), obj.elementSize());
                    bigger_image_display(position_y + chunk_height, position_x:position_x + chunk_width - 1, :) = repelem(chunk(size(chunk, 1), 1:size(chunk, 2), :), 1, obj.elementSize());
                    bigger_image_display(position_y:position_y + chunk_height - 1, position_x + chunk_width, :) = repelem(chunk(1:size(chunk, 1), size(chunk, 2), :), obj.elementSize(), 1);

                    obj.addCallback(drawLine(obj.axes, [position_x - 1, position_x - 1], [position_y, position_y + chunk_height + 1]));
                    obj.addCallback(drawLine(obj.axes, [position_x - 2, position_x + chunk_width - 1], [position_y + chunk_height, position_y + chunk_height]));
                    
                    if x == maximum_x && obj.matrix_type == MatrixType.TRIMATRIX && network_matrix
                        obj.addCallback(drawLine(obj.axes, [position_x + chunk_width, position_x + chunk_width], [position_y - 1, position_y + chunk_height + 1]));
                        obj.addCallback(drawLine(obj.axes, [position_x - 2, position_x + chunk_width], [position_y - 1, position_y - 1]));
                    end

                    if network == number_of_networks
                        top = position_y + chunk_height;
                        bottom = position_y + chunk_height + dimensions("label_size");
                        left = position_x;
                        right = position_x + chunk_width;

                        bigger_image_display(top:bottom, left:right, :) = colorChunk(obj.networks(x).color, dimensions("label_size") + 1, chunk_width + 1);
                        obj.drawBottomLabels(chunk_width, chunk_height, position_x, position_y, x);
                    end

                    position_x = position_x + chunk_width + 1;
                end
                position_y = position_y + chunk_height + 1;
            end
            obj.image_display.CData = bigger_image_display;
        end
        
        function obj = drawLeftLinesOnLabels(obj, top, bottom, left, right)
            import nla.gfx.drawLine
            drawLine(obj.axes, [left - 1, right], [top - 1, top - 1]);
            drawLine(obj.axes, [left - 1, right], [bottom, bottom]);
            drawLine(obj.axes, [left - 1, left - 1], [top - 1, bottom]);
        end

        function plotSignificanceMark(obj, chunk_width, chunk_height, axes, position_x, position_y)
            cell_x = position_x + (chunk_width / 2);
            cell_y = position_y + (chunk_height / 2);
            hold(axes, 'on');
            marker = plot(axes, cell_x, cell_y, 'x', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');

            if ~isequal(obj.network_clicked_callback, false)
                marker.ButtonDownFcn = {@obj.clickCallback, obj};
            end

        end

        function obj = drawBottomLabels(obj, chunk_width, chunk_height, position_x, position_y, x_location)
            import nla.gfx.colorChunk nla.gfx.drawLine
            dimensions = obj.image_dimensions;
            top = position_y + chunk_height;
            bottom = position_y + chunk_height + dimensions("label_size");
            left = position_x;
            right = position_x + chunk_width;

            obj.image_display.CData(top:bottom, left:right, :) = colorChunk(obj.networks(x_location).color, dimensions("label_size") + 1, chunk_width + 1);

            obj.addCallback(drawLine(obj.axes, [left - 1, left - 1], [top, bottom]));
            obj.addCallback(drawLine(obj.axes, [right, right], [top, bottom]));
            obj.addCallback(drawLine(obj.axes, [left - 1, right], [bottom, bottom]));
        end

    end
    
    
end
