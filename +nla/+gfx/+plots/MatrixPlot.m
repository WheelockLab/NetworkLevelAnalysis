classdef MatrixPlot < handle
    %MATRIXPLOT Base class for drawing a matrix or tri-matrix organized by
    % networks. 
    %
    % plot_object = MatrixPlot(figure, name, matrix_data, networks, figure_size, OPTIONS)
    % Options should be written as parameter-value pairs.
    % i.e. (...,"marked_networks", true, "lower_limit", 0,...)

    properties
        matrix % matrix data to plot, either full matrix or tri-matrix data
        % Vector of objects which must implement IndexGroup (nla.interfaces.IndexGroup), ie:
        % have a name, color, and a vector of indices corresponding to
        % data in the input matrix
        networks
        figure % figure used for plotting
        x_position % starting x position in the figure object
        y_position % starting y position in the figure object
        lower_limit % lower limit to clip input matrix
        upper_limit % upper limit to clip input matrix
        name % name of the plot
        figure_size % Size to display. Either nla.gfx.FigSize.SMALL or nla.gfx.FigSize.LARGE
        draw_legend % Legend on/off
        draw_colorbar % Colorbar on/off
        color_map % Colormap to use (enter 'turbo(256)' for default)
        marked_networks % networks to mark with a symbol
        discrete_colorbar % colorbar as discrete. TRUE == discrete, FALSE == continuous
        network_clicked_callback % Button function to add to each network. Used for clickable networks
        figure_margins % Margin on figure object yes/no.
        network_dimensions % Dimensions of the input
        axes % The axes of the plot
        image_display % The actual displayed values
        color_bar % The colorbar
        plot_scale % The scale and values being plotted (Linear, log, -log10, p-value, statistic p-value)
    end

    properties (Dependent)
        number_networks % This is the number of networks. Calculated property
        network_matrix % Calculated matrix for networks
        % Gives 'dictionary' of various dimension data. 
        % image_Height, image_width, offset_x, offset_y, plot_width, plot_height, display_matrix_size, label_size
        % Accessed by obj.image_dimensions("<something from list above>")
        image_dimensions 
        as_matrix % Convenience to give matrix object as an actual matlab matrix
        matrix_type % Type of matrix data input used
    end

    properties (Access = private, Constant)
        colorbar_width = 25; % Width of the colorbar
        colorbar_offset = 15; % Offset of the colorbar
        colorbar_text_w = 50; % Width of label on colorbar
        legend_offset = 5; % Offset of the Legend
        colormap_choices = {"Parula", "Turbo", "HSV", "Hot", "Cool", "Spring", "Summer", "Autumn", "Winter", "Gray",...
            "Bone", "Copper", "Pink"}; % Colorbar choices
    end

    methods
        function obj = MatrixPlot(figure, name, matrix, networks, figure_size, varargin)
            % MatrixPlot constructor
            % Gives plot object as output.
            % Requires inputs in this order:
            % figure
            % name
            % matrix
            % networks
            % figure size
            %
            % These arguments are optional with defaults
            % network_clicked_callback = false
            % marked_networks = false
            % figure_margins = nla.gfx.FigMargins.WHITESPACE
            % draw_legend = true
            % draw_colorbar = true
            % color_map = turbo(256)
            % lower_limit = -0.3
            % upper_limit = 0.3
            % x_position = 0
            % y_position = 0
            % discrete_colorbar = false
            % plot_scale = nla.gfx.ProbPlotMethod.DEFAULT
            import nla.gfx.createFigure
            matrix_input_parser = inputParser;
            addRequired(matrix_input_parser, 'figure');
            addRequired(matrix_input_parser, 'name');
            addRequired(matrix_input_parser, 'matrix');
            addRequired(matrix_input_parser, 'networks');
            addRequired(matrix_input_parser, 'figure_size');

            validNumberInput = @(x) isnumeric(x) && isscalar(x);
            validFunctionHandle = @(x) isa(x, 'function_handle');
            addParameter(matrix_input_parser, 'network_clicked_callback', false, validFunctionHandle);
            addParameter(matrix_input_parser, 'marked_networks', false);
            addParameter(matrix_input_parser, 'figure_margins', nla.gfx.FigMargins.WHITESPACE, @isenum);
            addParameter(matrix_input_parser, 'draw_legend', true, @islogical);
            addParameter(matrix_input_parser, 'draw_colorbar', true, @islogical);
            addParameter(matrix_input_parser, 'color_map', turbo(256));
            addParameter(matrix_input_parser, 'lower_limit', -0.3, validNumberInput);
            addParameter(matrix_input_parser, 'upper_limit', 0.3, validNumberInput);
            addParameter(matrix_input_parser, 'x_position', 0, validNumberInput);
            addParameter(matrix_input_parser, 'y_position', 0, validNumberInput);
            addParameter(matrix_input_parser, 'discrete_colorbar', false, @islogical);
            addParameter(matrix_input_parser, 'plot_scale', nla.gfx.ProbPlotMethod.DEFAULT, @isenum);
            
            parse(matrix_input_parser, figure, name, matrix, networks, figure_size, varargin{:});
            properties = {'figure', 'name', 'matrix', 'networks', 'figure_size', 'network_clicked_callback',...
                'marked_networks', 'figure_margins', 'draw_legend', 'draw_colorbar', 'color_map', 'lower_limit',...
                'upper_limit', 'x_position', 'y_position', 'discrete_colorbar', 'plot_scale'};
            for property = properties
                obj.(property{1}) = matrix_input_parser.Results.(property{1});
                if property{1} == "marked_networks"
                    if ~isequal(obj.marked_networks, false) && isa(obj.marked_networks, 'nla.TriMatrix')
                        obj.marked_networks = obj.marked_networks.asMatrix();
                    end
                end
            end

        end

        function displayImage(obj)
            % Call this method to plot the data. 

            % dependent props we're calling only once instead of many. Each call is a calculation.
            dimensions = obj.image_dimensions;
            number_of_networks = obj.number_networks;

            obj.network_dimensions = zeros(number_of_networks, number_of_networks, 4);

            % draw axes
            obj = obj.drawAxes();

            % initialization of the data that's going to become the image 
            image_data = NaN(dimensions("image_height"), dimensions("image_width"), 3);
            obj.image_display = image(obj.axes, image_data, 'XData', [1 obj.axes.Position(3)],...
                'YData', [1 obj.axes.Position(4)]);
            % add callback for clicking on image
            obj.addCallback(obj.image_display);

            % set limit on axes
            obj.axes.XLim = [0 obj.image_display.XData(2)];
            obj.axes.YLim = [0 obj.image_display.YData(2) + 1];
            hold(obj.axes, 'on')
            obj = obj.embiggenMatrix();

            % Makes NaNs transparent
            obj.image_display.AlphaData = ~isnan(obj.image_display.CData(:,:,1));
            
            if obj.draw_legend
                obj.createLegend();
            end

            if obj.draw_colorbar
                obj.createColorbar();
            end
           
            % Title plot and center title
            if ~isempty(obj.name)
                plot_title = title(obj.axes, ' ');
                text(obj.axes, dimensions("plot_width") / 2 , dimensions("offset_y") / 2, obj.name,...
                    'FontName', plot_title.FontName, 'FontSize', 14, 'FontWeight', plot_title.FontWeight,...
                    'HorizontalAlignment', 'center');
            end

            obj.fixRendering();
            hold(obj.axes, 'off') % This may have been turned on. Does nothing if it wasn't.

        end

        % getters for dependent properties
        function value = get.number_networks(obj)
            value = numel(obj.networks);
        end

        function value = get.network_matrix(obj)
            % Is this a network matrix or an edge matrix
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

            % The actual size of everything
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
            % Matlab does not have a python-like dictionary. This is one, or a struct. 
            value = containers.Map(["image_height" "image_width" "offset_x" "offset_y" "plot_width" "plot_height"...
                 "display_matrix_size" "label_size"], dimensions);
        end

        function value = get.as_matrix(obj)
            value = obj.matrix.asMatrix();
        end

        function value = get.matrix_type(obj)
            % Is this a TriMatrix or square?
            import nla.gfx.MatrixType
            value = MatrixType.MATRIX;
            if isa(obj.matrix, 'nla.TriMatrix')
                value = MatrixType.TRIMATRIX;
            end
        end
    end

    methods (Access = protected)
        function element_size = elementSize(obj)
            % Basic method to calculate Element Size
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

        function obj = drawAxes(obj)
            % Creates the axes for the plot.
            obj.axes = uiaxes(obj.figure, 'Position', [obj.x_position, obj.y_position,...
                obj.image_dimensions("image_width"), obj.image_dimensions("image_height")]);
            axis(obj.axes, 'image');
            obj.axes.XAxis.TickLabels = {};
            obj.axes.YAxis.TickLabels = {};
        end

        function clickCallback(obj, ~, ~)
            %  Method which determines which coordinates were clicked and runs 'network_clicked_callback'
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
                            obj.network_clicked_callback(y_iterator, x_iterator)
                        end
                    end
                end
            end
        end
        
        function addCallback(obj, x)
            % Add callbacks that are clickable to parts of the plot
            if ~isequal(obj.network_clicked_callback, false)
                x.ButtonDownFcn = @obj.clickCallback;
            end
        end

        function obj = embiggenMatrix(obj, varargin)
            % Enlarges data points of matrix for easier viewing. 
            % Also adds the network colorbars to the left axis and bottom axis.
            import nla.gfx.colorChunk nla.gfx.MatrixType nla.gfx.drawLine

            % If there are no inputs (like initial rendering) then we use defaults
            % If there were inputs, that means we're scaling the colorbar.
            if isempty(varargin)
                initial_render = true; % Controls whether or not to add the bars on the side and bottom
                upper_value = obj.upper_limit;
                lower_value = obj.lower_limit;
            else
                initial_render = false;
                upper_value = str2double(varargin{2});
                lower_value = str2double(varargin{1});
            end

            number_of_networks = obj.number_networks;
            dimensions = obj.image_dimensions;
            network_matrix = obj.network_matrix;
            matrix_as_matrix = obj.as_matrix;

            position_y = dimensions("offset_y") + 2;
            if ~isempty(obj.name)
                position_y = position_y + 20;
            end
            starting_y = position_y;

            for network = 1:number_of_networks
                network_indexes = network;
                if ~network_matrix
                    network_in_bound = obj.networks(network).indexes <= size(matrix_as_matrix, 1);
                    network_indexes = obj.networks(network).indexes(network_in_bound);
                end

                chunk_height = numel(network_indexes) * obj.elementSize();
                
                % Left side of matrix color bars
                if isequal(initial_render, true)
                   obj.drawLeftLinesOnLabels(position_y, chunk_height, dimensions, network);
                end
                
                position_x = dimensions("label_size") + dimensions("offset_x") + 3;
                starting_x = position_x;
                maximum_x = number_of_networks;
                if obj.matrix_type == MatrixType.TRIMATRIX
                    maximum_x = network;
                end

                for x = 1:maximum_x
                    x_index = x;
                    if ~network_matrix
                        x_in_bound = obj.networks(x).indexes < size(matrix_as_matrix, 1);
                        x_index = obj.networks(x).indexes(x_in_bound);
                    end

                    chunk_width = numel(x_index) * obj.elementSize();

                    % Get color for chunks
                    chunk_raw = matrix_as_matrix(network_indexes, x_index);
                    chunk_color = obj.getChunkColor(chunk_raw, upper_value, lower_value);

                    % Apply colors to chunks
                    obj.applyColorToData(position_x, position_y, chunk_height, chunk_width, chunk_color);

                    if isequal(initial_render, true)
                        % plot signifance marker
                        if ~isequal(obj.marked_networks, false) && isequal(obj.marked_networks(network, x), true)
                            obj.plotSignificanceMark(chunk_width, chunk_height, position_x, position_y);
                        end
                        
                        if ~isequal(obj.network_clicked_callback, false)
                            obj.network_dimensions(x, network, :) = [position_x, position_x + chunk_width - 1,...
                                position_y, position_y + chunk_height - 1];
                        end
                        % Add callbacks to all the squares
                        obj.addCallback(drawLine(obj.axes, [position_x - 1, position_x - 1],...
                            [position_y, position_y + chunk_height + 1]));
                        obj.addCallback(drawLine(obj.axes, [position_x - 2, position_x + chunk_width - 1],...
                            [position_y + chunk_height, position_y + chunk_height]));

                        if x == maximum_x && obj.matrix_type == MatrixType.TRIMATRIX && ~isequal(network_matrix, false)
                            obj.addCallback(drawLine(obj.axes, [position_x + chunk_width, position_x + chunk_width],...
                                [position_y - 1, position_y + chunk_height + 1]));
                            obj.addCallback(drawLine(obj.axes, [position_x - 2, position_x + chunk_width],...
                                [position_y - 1, position_y - 1]));
                        end

                        % Is this the last network of a TriMatrix. Then we're done and need to add the bottom
                        if network == number_of_networks
                            top = position_y + chunk_height;
                            bottom = position_y + chunk_height + dimensions("label_size");
                            left = position_x;
                            right = position_x + chunk_width;

                            obj.image_display.CData(top:bottom, left:right, :) = colorChunk(obj.networks(x).color,...
                                dimensions("label_size") + 1, chunk_width + 1);
                            obj.drawBottomLabels(chunk_width, chunk_height, position_x, position_y, x);
                        end
                    end
                    position_x = position_x + chunk_width + 1;
                end
                position_y = position_y + chunk_height + 1;
            end

            if obj.matrix_type == MatrixType.TRIMATRIX && ~network_matrix && initial_render
                drawLine(obj.axes, [starting_x - 1, position_x - 1],...
                    [starting_y - 3 + obj.elementSize(), position_y - 2], 'w');
                drawLine(obj.axes, [starting_x - 2, position_x - 1],...
                    [starting_y - 3 + obj.elementSize(), position_y - 1]);
            end
        end
        
        function drawLeftLinesOnLabels(obj, position_y, chunk_height, dimensions, network)
            % Draws the left side lines on the plot
            import nla.gfx.drawLine nla.gfx.colorChunk

            top = position_y;
            bottom = position_y + chunk_height;
            left = dimensions("offset_x") + 2;
            right = dimensions("offset_x") + dimensions("label_size") + 1;
            obj.image_display.CData(top:bottom, left:right+1, :) = colorChunk(obj.networks(network).color,...
                chunk_height + 1, dimensions("label_size") + 1);

            drawLine(obj.axes, [left - 1, right], [top - 1, top - 1]);
            drawLine(obj.axes, [left - 1, right], [bottom, bottom]);
            drawLine(obj.axes, [left - 1, left - 1], [top - 1, bottom]);
        end

        function plotSignificanceMark(obj, chunk_width, chunk_height, position_x, position_y)
            % Adds significance markers
            cell_x = position_x + (chunk_width / 2);
            cell_y = position_y + (chunk_height / 2);
            marker = plot(obj.axes, cell_x, cell_y, 'x', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');

            if ~isequal(obj.network_clicked_callback, false)
                marker.ButtonDownFcn = @obj.clickCallback;
            end

        end

        function obj = drawBottomLabels(obj, chunk_width, chunk_height, position_x, position_y, x_location)
            % Draws the bottom labels and lines
            import nla.gfx.colorChunk nla.gfx.drawLine

            dimensions = obj.image_dimensions;
            top = position_y + chunk_height;
            bottom = position_y + chunk_height + dimensions("label_size");
            left = position_x;
            right = position_x + chunk_width;

            obj.image_display.CData(top:bottom, left:right, :) = colorChunk(obj.networks(x_location).color,...
                dimensions("label_size") + 1, chunk_width + 1);

            obj.addCallback(drawLine(obj.axes, [left - 1, left - 1], [top, bottom]));
            obj.addCallback(drawLine(obj.axes, [right, right], [top, bottom]));
            obj.addCallback(drawLine(obj.axes, [left - 1, right], [bottom, bottom]));
        end

        function fixRendering(obj)
            % Fix some rendering options that we don't need/like (hiding options, toolbars, other things)

            nla.gfx.hideAxes(obj.axes);
            obj.axes.DataAspectRatio = [1, 1, 1];
            obj.axes.Toolbar.Visible = 'off';
            disableDefaultInteractivity(obj.axes);
            if ~obj.network_matrix
                obj.axes.Units = 'pixels';
                axes_position = obj.axes.Position;
                obj.axes.XLim = [0 axes_position(3)];
                obj.axes.YLim = [0 axes_position(4)];
            end
        end

        function createLegend(obj)
            % Creates the Legend
            entries = [];
            for network = 1:obj.number_networks
                entry = bar(obj.axes, NaN);
                entry.FaceColor = obj.networks(network).color;
                entry.DisplayName = obj.networks(network).name;
                entries = [entries entry];
            end

            display_legend = legend(obj.axes, entries); % Legend object

            dimensions = obj.image_dimensions;
            display_legend.Units = 'pixels';
            display_legend_width = display_legend.Position(3);
            display_legend_height = display_legend.Position(4);
            display_legend.Position = [...
                obj.x_position + dimensions("plot_width") - display_legend_width - dimensions("offset_x") - obj.legend_offset,...
                obj.y_position + dimensions("plot_height") - display_legend_height - dimensions("offset_y"),...
                display_legend_width, display_legend_height...
            ];
        end

        function createColorbar(obj, varargin)
            % Creates the colorbar
            % Annoyance: obj.color_map is a property, colormap is a command. Same with color_bar and colorbar

            % If there are arguments, it means that this came from changing the colorbar. If not, using defaults
            if isempty(varargin)
                upper_value = obj.upper_limit;
                lower_value = obj.lower_limit;
            else
                obj.color_bar.TickLabels = {};
                obj.color_bar.Ticks = [];
                upper_value = str2double(varargin{2});
                lower_value = str2double(varargin{1});
            end

            if obj.discrete_colorbar
                number_of_ticks = double(upper_value - lower_value);
                display_colormap = obj.color_map(floor(...
                    (size(obj.color_map, 1) - 1) * [0:number_of_ticks] ./ number_of_ticks) + 1, :);
                display_colormap = repelem(display_colormap, 2, 1);
                display_colormap = display_colormap(2:((number_of_ticks + 1) * 2 - 1), :);
                colormap(obj.axes, display_colormap);
            else
                number_of_ticks = min(size(obj.color_map, 1) - 1, 10);
                colormap(obj.axes, obj.color_map)
            end

            obj.color_bar = colorbar(obj.axes);

            ticks = [0:number_of_ticks];
            obj.color_bar.Ticks = double(ticks) ./ number_of_ticks;

            labels = {};
            for tick = ticks
                labels{tick + 1} = sprintf(...
                    "%.2g", lower_value + (tick * ((double(upper_value - lower_value) / number_of_ticks)))...
                );
            end
            obj.color_bar.TickLabels = labels;
            
            dimensions = obj.image_dimensions;
            obj.color_bar.Units = 'pixels';
            obj.color_bar.Location = 'east';
            % This tells the plot where to place the colorbar. It's a standard matlab position object, four coordinates.
            % Formatting to try and keep 120 max line makes it ugly.
            obj.color_bar.Position = [obj.color_bar.Position(1) - dimensions("offset_x"),...
                obj.color_bar.Position(2) + dimensions("offset_y"), obj.colorbar_width,...
                dimensions("image_height") - (dimensions("offset_y") * 2) - 20];
            obj.color_bar.Title.Position(2) = 0 - dimensions("offset_y") * 2 / 3;
            obj.color_bar.Title.String = sprintf("Click to\nchange scale\n");
            obj.color_bar.Title.FontSize = 7;

            % Enables callback for clicking on colorbar to scale data
            set(obj.color_bar, 'ButtonDownFcn', @obj.openModal)

            caxis(obj.axes, [0, 1]);
        end

        function openModal(obj, source, ~)
            % Callback for clicking on the colorbar.
            % This opens a modal with the upper and lower bounds along with a radio selector between linear and 
            % log. This only works for a "regular" log scale, not the -log10 scale. Still working on that one
            import nla.gfx.ProbPlotMethod

            % source is the colorbar, not the figure
            d = figure('WindowStyle', 'normal', "Units", "pixels", 'Position', [source.Position(1), source.Position(2),...
                source.Position(3) * 15, source.Position(4)/ 1.75]);
            % These are the boxes that are the upper and lower end of the scale
            upper_limit_box = uicontrol('Style', 'edit', "Units", "pixels",...
                'Position', [90, d.Position(4) - 30, 100, 30], "String", obj.upper_limit);
            upper_limit_box.Position(4) = upper_limit_box.FontSize * 2;
            lower_limit_box = uicontrol('Style', 'edit', "Units", "pixels",...
                'Position', [90, upper_limit_box.Position(2) - 30, 100, 30], "String", obj.lower_limit); 
            lower_limit_box.Position(4) = lower_limit_box.FontSize * 2;
            uicontrol('Style', 'text', 'String', 'Upper Limit', "Units", "pixels", 'Position',...
                [upper_limit_box.Position(1) - 80, upper_limit_box.Position(2) - 2, 80, upper_limit_box.Position(4)]);
            uicontrol('Style', 'text', 'String', 'Lower Limit', "Units", "pixels", 'Position',...
                [lower_limit_box.Position(1) - 80, lower_limit_box.Position(2) - 2, 80, lower_limit_box.Position(4)]);

            % These are the buttons that make the scale log or linear
            scaleBaseButtons = uibuttongroup(d, "Units", "pixels", "Position", [10, lower_limit_box.Position(2) - 40, 150, 30]);
            linear_button = uicontrol(scaleBaseButtons, "Style", "radiobutton", "String", "Linear", "Units", "pixels",...
                "Position", [10, 5, 60, 20]);
            log_button = uicontrol(scaleBaseButtons, "Style", "radiobutton", "String", "Log", "Units", "pixels",...
                "Position", [70, 5, 60, 20]);
            % Here we're setting the initial setting for the linear or log button
            if obj.plot_scale == ProbPlotMethod.DEFAULT || obj.plot_scale == STATISITC
                selected_value = linear_button;
            else
                selected_value = log_button;
            end
            scaleBaseButtons.SelectedObject = selected_value;
            
            % Color Map selector
            % Adapted from colormap-dropdown: https://www.mathworks.com/matlabcentral/fileexchange/43659-colormap-dropdown-menu
            
            uicontrol("Style", "text", "string", "Colormaps", "Units", "pixels",...
                "Position", [10, scaleBaseButtons.Position(2) - 45, 80, 25]);
            color_map_select = uicontrol('Style', 'popupmenu',...
                'Position', [100, scaleBaseButtons.Position(2) - 45, 250, 30]);
            initial_colors = 16;
            colormap_html = [];
            for colors = 1:numel(obj.colormap_choices)
                colormap_function = str2func(strcat(strcat("@(x) ",lower(obj.colormap_choices{colors}), "(x)")));
                CData = colormap_function(initial_colors);
                new_html = '<HTML>';
                for color_iterator = 1:initial_colors
                    hex_code = nla.gfx.rgb2hex([CData(color_iterator, 1), CData(color_iterator, 2),...
                        CData(color_iterator, 3)]);
                    new_html = [new_html '<FONT bgcolor="' hex_code ' "color="' hex_code '">__</FONT>'];
                end
                %new_html = new_html(1:end-2);
                new_html = [new_html '</HTML>'];
                colormap_html = [colormap_html; {new_html}];
            end
            set(color_map_select, "Value", 1, "String", colormap_html);

            apply_button_position = [10, 10, 100, 30];
            apply_button = uicontrol('String', 'Apply',...
                'Callback', {@obj.applyScale, upper_limit_box, lower_limit_box, scaleBaseButtons, color_map_select},...
                "Units", "pixels",...
                'Position', apply_button_position);
            close_button_position = [apply_button.Position(1) + apply_button.Position(3) + 10,...
                apply_button.Position(2), apply_button.Position(3), apply_button.Position(4)];
            uicontrol('String', 'Close', 'Callback', @(~, ~)close(d), "Units", "pixels", 'Position',...
                close_button_position);
        end

        function applyScale(obj, ~, ~, upper_limit_box, lower_limit_box, button_group, color_map_select)
            % This callback gets the colormap/scale and then applies the new bounds to the data.
            % Only works with APPLY button, will not work with only CLOSE
        
            import nla.net.result.NetworkResultPlotParameter

            discrete_colors = NetworkResultPlotParameter().default_discrete_colors;
            color_map = get(color_map_select, "Value");
            if get(get(button_group, "SelectedObject"), "String") == "Linear"
                obj.color_map = NetworkResultPlotParameter.getColormap(discrete_colors, get(upper_limit_box, "String"),...
                    obj.colormap_choices{color_map});
            else
                obj.color_map = NetworkResultPlotParameter.getLogColormap(discrete_colors, obj.matrix,...
                    get(upper_limit_box, "String"). obj.colormap_choices{color_map});
            end
            obj.embiggenMatrix(get(lower_limit_box, "String"), get(upper_limit_box, "String"));
            obj.createColorbar(get(lower_limit_box, "String"), get(upper_limit_box, "String"));
        end

        function chunk_color = getChunkColor(obj, chunk_raw, upper_value, lower_value)
            % Get color for the chunk (square)
            chunk_color = nla.gfx.valToColor(chunk_raw, lower_value, upper_value, obj.color_map);
            chunk_color(isnan(chunk_raw)) = NaN; % puts all NaNs back removed with valToColor
        end

        function applyColorToData(obj, position_x, position_y, chunk_height, chunk_width, chunk_color)
            % Fill in the chunks (squares) with color
            obj.image_display.CData(position_y:position_y + chunk_height - 1, position_x:position_x + chunk_width - 1, :) =...
                repelem(chunk_color, obj.elementSize(), obj.elementSize());
            obj.image_display.CData(position_y + chunk_height, position_x:position_x + chunk_width - 1, :) =...
                repelem(chunk_color(size(chunk_color, 1), 1:size(chunk_color, 2), :), 1, obj.elementSize());
            obj.image_display.CData(position_y:position_y + chunk_height - 1, position_x + chunk_width, :) =...
                repelem(chunk_color(1:size(chunk_color, 1), size(chunk_color, 2), :), obj.elementSize(), 1);
        end
    end
end
