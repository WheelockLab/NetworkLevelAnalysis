classdef ChordPlotter < handle
% CHORDPLOTTER Draws network test results in Chord Figures
%   Object takes the brain network atlas and the edge test results to initialize
%   generateChordFigure creates the chord plots for the network test results
%   The parameters used as an input are fron NetworkResultPlotParameter
%   Chord type is coming from the test options/input_struct.

    properties (Constant)
        axis_width = 750; % Constant for the size of the chord
        trimatrix_width = 500; % Constant for the size of the Trimatrix plotted with
        bottom_text_height = 250; % How far from the bottom of the trimatrix the text appears
        colormap_choices = {"Parula", "Turbo", "HSV", "Hot", "Cool", "Spring", "Summer", "Autumn", "Winter", "Gray",...
            "Bone", "Copper", "Pink"}; % Colorbar choices
    end

    properties
        network_atlas % Network Atlas for the data
        edge_test_result % Edge test results
        split_plot = false % This is an option that is set automatically during operation. 
        edge_plot_type = "nla.gfx.EdgeChordPlotMethod.PROB" % Default chord type for edges
        chord_plotter = false
    end

    methods
        function obj = ChordPlotter(network_atlas, edge_test_result)
            % Constructor. Inputs = network_atlas, edge_test_result
            % Output = ChordPlotter object
            if nargin > 0
                obj.network_atlas = network_atlas;
            end
            if nargin > 1
                obj.edge_test_result = edge_test_result;
            end
        end

        function generateChordFigure(obj, parameters, chord_type, parent_figure)
            % generateChordFigure plots chords for a network test
            import nla.gfx.SigType nla.net.result.plot.PermutationTestPlotter nla.gfx.EdgeChordPlotMethod nla.gfx.setTitle

            coefficient_bounds = [0, parameters.p_value_plot_max];
            if isfield(parameters, "lower_bound")
                coefficient_bounds(1) = parameters.lower_bound;
            end
            if parameters.significance_type == SigType.INCREASING && parameters.p_value_plot_max < 1
                coefficient_bounds = [parameters.p_value_plot_max, 1];
            end

            % Check if it's an edge chord plot, and if so, do we plot positive and negative separately
            if isfield(parameters, 'edge_chord_plot_method')
                obj.edge_plot_type = parameters.edge_chord_plot_method;
                if obj.edge_plot_type == "nla.gfx.EdgeChordPlotMethod.COEFF_SPLIT" || obj.edge_plot_type == "nla.gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT"
                    obj.split_plot = true;
                end
            end

            % Create the figure windows that all the plots will go in
            if obj.split_plot && chord_type == "nla.PlotType.CHORD_EDGE"
                plot_figure = nla.gfx.createFigure((obj.axis_width * 2), obj.axis_width);
            else
                plot_figure = nla.gfx.createFigure(obj.axis_width , obj.axis_width);
            end
            if ~isequal(parent_figure, false)
                nla.gfx.moveFigToParentUILocation(plot_figure, parent_figure);
            end
            
            % Plot a standard chord plot
            if chord_type == "nla.PlotType.CHORD"
                figure_axis = axes(plot_figure, 'Units', 'pixels', 'Position', [0, 0, obj.axis_width,...
                    obj.axis_width]);
                nla.gfx.hideAxes(figure_axis);

                insignificance = coefficient_bounds(2);
                if parameters.significance_type == "nla.gfx.SigType.INCREASING"
                    insignificance = coefficient_bounds(1);
                end

                % thresholding below the "insignificance" value
                statistic_matrix = copy(parameters.statistic_plot_matrix);
                statistic_matrix.v(~parameters.significance_plot.v) = insignificance;
                obj.chord_plotter = nla.gfx.chord.ChordPlot(obj.network_atlas, figure_axis, 500, statistic_matrix,...
                    'color_map', parameters.color_map, 'direction', parameters.significance_type, 'upper_limit',...
                    coefficient_bounds(2), 'lower_limit', coefficient_bounds(1), 'chord_type', chord_type);
                obj.chord_plotter.drawChords();
                setTitle(figure_axis, parameters.name_label)
                settings_menu = uimenu(plot_figure, 'Text', 'Settings');
                change_scale_option = uimenu(settings_menu,'Text','Change Scale');
                change_scale_option.MenuSelectedFcn = {@obj.adjustScale, coefficient_bounds, plot_figure, parameters, chord_type};
                change_color_map = uimenu(settings_menu, 'Text', 'Change Color Map');
                change_color_map.MenuSelectedFcn = {@obj.adjustColor, plot_figure, parameters, chord_type};
            else
                % Plot edge chord
                obj.generateEdgeChordFigure(plot_figure, parameters, chord_type, parent_figure)
            end


        end
    end

    methods (Access = protected)
        function generateEdgeChordFigure(obj, plot_figure, parameters, chord_type, parent_figure)
            % generateEdgeChordFigure generates the edge chord plotting
            import nla.gfx.EdgeChordPlotMethod nla.gfx.setTitle

            if isfield(parameters, "lower_bound")
                coefficient_min = parameters.lower_bound;
                coefficient_max = parameters.p_value_plot_max;
            else
                range_limit = std(obj.edge_test_result.coeff.v) * 5;
                coefficient_min = -range_limit;
                coefficient_max = range_limit;
            end

            clipped_values = nla.TriMatrix(obj.network_atlas.numROIs(), nla.TriMatrixDiag.REMOVE_DIAGONAL);
            clipped_values.v = obj.edge_test_result.coeff.v;
            clipped_values.v(obj.edge_test_result.coeff.v > 0) = 0;
            clipped_values_positive = nla.TriMatrix(obj.network_atlas.numROIs(), nla.TriMatrixDiag.REMOVE_DIAGONAL);
            clipped_values_positive.v = obj.edge_test_result.coeff.v;
            clipped_values_positive.v(obj.edge_test_result.coeff.v < 0) = 0;

            color_map = turbo(1000);
            significance_type = "nla.gfx.SigType.ABS_INCREASING";
            insignificance = 0; % This is basically the background for the plot
            % This is the title for the positive (or non-split) chord plot
            positive_title = sprintf("Edge-level correlation (P < %g) (Within Significant Net-Pair)",...
                obj.edge_test_result.prob_max);
            % This is the title for the negative chord plot
            negative_title = sprintf("Negative edge-level correlation (P < %g) (Within Significant Net-Pair)",...
                obj.edge_test_result.prob_max);

            % There are some settings that need to be changed depending on the specific type of edge plot
            switch obj.edge_plot_type
                case "nla.gfx.EdgeChordPlotMethod.COEFF"
                    main_title = positive_title;
                    if isfield(parameters, "lower_bound")
                        coefficient_min = parameters.lower_bound;
                        coefficient_max = parameters.p_value_plot_max;
                    end

                case "nla.gfx.EdgeChordPlotMethod.COEFF_SPLIT"
                    main_title = negative_title;
                    positive_main_title = positive_title;
                    if isfield(parameters, "lower_bound")
                        coefficient_min = parameters.lower_bound;
                        coefficient_max = parameters.p_value_plot_max;
                    end

                case "nla.gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT"
                    if isfield(parameters, "lower_bound")
                        coefficient_min = parameters.lower_bound;
                        coefficient_max = parameters.p_value_plot_max;
                    else
                        coefficient_min = obj.edge_test_result.coeff_range(1);
                        coefficient_max = obj.edge_test_result.coeff_range(2);
                    end

                    main_title = negative_title;
                    positive_main_title = positive_title;

                case "nla.gfx.edgeChordPlotMethod.COEFF_BASE"
                    if isfield(parameters, "lower_bound")
                        coefficient_min = parameters.lower_bound;
                        coefficient_max = parameters.p_value_plot_max;
                    else
                        coefficient_min = obj.edge_test_result.coeff_range(1);
                        coefficient_max = obj.edge_test_result.coeff_range(2);
                    end

                    main_title = positive_title;

                otherwise
                    color_map_base = parula(1000);
                    color_map = flip(color_map_base(ceil(logspace(-3, 0, 1000) .* 1000), :));

                    clipped_values.v = obj.edge_test_result.prob.v;
                    significance_type = "nla.gfx.SigType.DECREASING";
                    if isfield(parameters, "lower_bound")
                        coefficient_min = parameters.lower_bound;
                        coefficient_max = parameters.p_value_plot_max;
                    else
                        coefficient_min = 0;
                        coefficient_max = obj.edge_test_result.prob_max;
                    end

                    insignificance = 1;
                    main_title = sprintf("Edge-level P-values (P < %g) (Within Significant Net-Pair)",...
                        obj.edge_test_result.prob_max);
            end
            coefficient_bounds = [coefficient_min, coefficient_max];

            % Filtering/Thresholding out values
            for network1 = 1:obj.network_atlas.numNets()
                for network2 = 1:network1
                    if ~parameters.significance_plot.get(network1, network2)
                        clipped_values.set(obj.network_atlas.nets(network1).indexes, obj.network_atlas.nets(network2).indexes,...
                            insignificance);
                        if obj.split_plot
                            clipped_values_positive.set(obj.network_atlas.nets(network1).indexes, obj.network_atlas.nets(network2).indexes,...
                            insignificance);
                        end
                    end
                end
            end

            plot_axis = axes(plot_figure, 'Units', 'pixels', 'Position', [0, 0, obj.axis_width - 50,...
                obj.axis_width - 50]);
            nla.gfx.hideAxes(plot_axis);
            plot_axis.Visible = true;

            if obj.split_plot && chord_type == "nla.PlotType.CHORD_EDGE" && (...
                obj.edge_plot_type == "nla.gfx.EdgeChordPlotMethod.COEFF_SPLIT" || obj.edge_plot_type == "nla.gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT"...
            )
                positive_chord_plotter = nla.gfx.chord.ChordPlot(obj.network_atlas, plot_axis, 450, clipped_values_positive,...
                    'direction', significance_type, 'chord_type', chord_type, 'color_map', parameters.color_map, 'lower_limit',...
                    coefficient_bounds(1), 'upper_limit', coefficient_bounds(2));
                positive_chord_plotter.drawChords();
                setTitle(plot_axis, positive_main_title);

                % create another axis, I hate this naming but we can overwrite the old one
                plot_axis = axes(plot_figure, 'Units', 'pixels', 'Position',...
                    [obj.axis_width - 100, 0 , obj.axis_width - 50, obj.axis_width - 50]);
                nla.gfx.hideAxes(plot_axis);
                plot_axis.Visible = true;
            end

            obj.chord_plotter = nla.gfx.chord.ChordPlot(obj.network_atlas, plot_axis, 450, clipped_values, 'chord_type', chord_type,...
                'direction', significance_type, 'color_map', parameters.color_map, 'lower_limit', coefficient_bounds(1), 'upper_limit', coefficient_bounds(2));
            obj.chord_plotter.drawChords();
            setTitle(plot_axis, main_title);

            colormap(plot_axis, parameters.color_map);
            color_bar = colorbar(plot_axis);
            color_bar.Units = 'pixels';
            color_bar.Location = 'east';
            color_bar.Position = [color_bar.Position(1) + 25, color_bar.Position(2) + 100, color_bar.Position(3),...
                color_bar.Position(4) - 200];

            number_ticks = 10;
            ticks = [0:number_ticks];
            color_bar.Ticks = double(ticks) ./ number_ticks;

            labels = {};
            for tick = ticks
                labels{tick + 1} = sprintf("%.2g", coefficient_min + (tick * ((coefficient_max - coefficient_min) / number_ticks)));
            end
            color_bar.TickLabels = labels;

            settings_menu = uimenu(plot_figure, 'Text', 'Settings');
            change_scale_option = uimenu(settings_menu,'Text','Change Scale');
            change_scale_option.MenuSelectedFcn = {@obj.adjustScale, coefficient_bounds, plot_figure, parameters, chord_type};
            change_color_map = uimenu(settings_menu, 'Text', 'Change Color Map');
            change_color_map.MenuSelectedFcn = {@obj.adjustColor, plot_figure, parameters, chord_type};
        end

        function adjustScale(obj, src, ~, bounds, plot_figure, parameters, chord_type)
            chord_figure = src.Parent.Parent;
            modal = figure('WindowStyle', 'normal', 'Units', 'pixels', 'Position',...
                [chord_figure.Position(1), chord_figure.Position(2), chord_figure.Position(3) / 3, chord_figure.Position(4) / 3]);
            
            upper_limit_box = uicontrol('Style', 'edit', "Units", "pixels", 'Position', [90, 130, 100, 30], "String",...
                bounds(2));
            upper_limit_box.Position(4) = upper_limit_box.FontSize * 2;
            lower_limit_box = uicontrol('Style', 'edit', "Units", "pixels", 'Position', [90, 100, 100, 30], "String",...
                bounds(1)); 
            lower_limit_box.Position(4) = lower_limit_box.FontSize * 2;

            uicontrol('Style', 'text', 'String', 'Upper Limit', "Units", "pixels", 'Position',...
                [upper_limit_box.Position(1) - 80, upper_limit_box.Position(2) - 2, 80, upper_limit_box.Position(4)]);
            uicontrol('Style', 'text', 'String', 'Lower Limit', "Units", "pixels", 'Position',...
                [lower_limit_box.Position(1) - 80, lower_limit_box.Position(2) - 2, 80, lower_limit_box.Position(4)]);

            apply_button_position = [10, 10, 100, 30];
            apply_button = uicontrol('String', 'Apply',...
                "Callback", {@obj.applyScale, upper_limit_box, lower_limit_box, false, plot_figure, parameters, chord_type},...
                "Units", "pixels",...
                'Position', apply_button_position);
            
            close_button_position = [apply_button.Position(1) + apply_button.Position(3) + 10,...
                apply_button.Position(2), apply_button.Position(3), apply_button.Position(4)];
            uicontrol('String', 'Close', 'Callback', @(~, ~)close(modal), "Units", "pixels", 'Position',...
                close_button_position);
        end

        function adjustColor(obj, src, ~, plot_figure, parameters, chord_type)
            chord_figure = src.Parent.Parent;
            modal = figure('WindowStyle', 'normal', 'Units', 'pixels', 'Position',...
                [chord_figure.Position(1), chord_figure.Position(2), chord_figure.Position(3) / 2, chord_figure.Position(4) / 3]);

            % Color Map selector
            % Adapted from colormap-dropdown: https://www.mathworks.com/matlabcentral/fileexchange/43659-colormap-dropdown-menu 

            color_map_select = uicontrol('Style', 'popupmenu',...
                'Position', [90, 130, 275, 30], "Units", "pixels",...
                'FontName', 'Courier');
            uicontrol("Style", "text", "string", "Colormaps", "Units", "pixels",...
                "Position", [color_map_select.Position(1) - 80, color_map_select.Position(2) - 2, 80, color_map_select.Position(4)]);
            initial_colors = 16;
            colormap_html = {};
            for colors = 1:numel(obj.colormap_choices)
                colormap_function = str2func(strcat(strcat("@(x) ",lower(obj.colormap_choices{colors})), "(x)"));
                CData = colormap_function(initial_colors);
                new_html_start = '<HTML> ';
                new_html = '';
                for color_iterator = initial_colors:-1:1
                    hex_code = nla.gfx.rgb2hex([CData(color_iterator, 1), CData(color_iterator, 2),...
                        CData(color_iterator, 3)]);
                    new_html = [new_html '<FONT bgcolor="' hex_code ' "color="' hex_code '">__</FONT>'];
                end
                new_html_end = [new_html ' </HTML>'];
                new_html = [new_html_start new_html_end];
                colormap_html = [colormap_html; new_html];
            end

            if ~isfield(parameters, "color_map_name")
                parameters.color_map_name = 1;
            end
            set(color_map_select, "Value", parameters.color_map_name, "String", colormap_html);

            apply_button_position = [10, 10, 100, 30];
            apply_button = uicontrol('String', 'Apply',...
                "Callback", {@obj.applyScale, false, false, color_map_select, plot_figure, parameters, chord_type},...
                "Units", "pixels",...
                'Position', apply_button_position);
            
            close_button_position = [apply_button.Position(1) + apply_button.Position(3) + 10,...
                apply_button.Position(2), apply_button.Position(3), apply_button.Position(4)];
            uicontrol('String', 'Close', 'Callback', @(~, ~)close(modal), "Units", "pixels", 'Position',...
                close_button_position);
        end

        function applyScale(obj, src, ~, upper_limit_box, lower_limit_box, color_map, plot_figure, parameters, chord_type)
            
            if ~isequal(upper_limit_box, false)
                parameters.p_value_plot_max = str2double(get(upper_limit_box, "String"));
                parameters.lower_bound = str2double(get(lower_limit_box, "String"));
            end

            if ~isequal(color_map, false)
                color_map = get(color_map, "Value");
                color_map_name = str2func(lower(obj.colormap_choices{color_map}));
                parameters.color_map = color_map_name(1000);
                parameters.color_map_name = color_map;
            end

            obj.generateChordFigure(parameters, chord_type, plot_figure)

            close(plot_figure);
            close(src.Parent);
        end
    end
end