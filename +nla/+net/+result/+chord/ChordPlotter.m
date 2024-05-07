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
    end

    properties
        network_atlas % Network Atlas for the data
        edge_test_result % Edge test results
        split_plot = false % This is an option that is set automatically during operation. 
        edge_plot_type = nla.gfx.EdgeChordPlotMethod.PROB % Default chord type for edges
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

        function generateChordFigure(obj, parameters, chord_type)
            % generateChordFigure plots chords for a network test
            import nla.gfx.SigType nla.net.result.plot.NoPermutationPlotter nla.gfx.EdgeChordPlotMethod

            coefficient_bounds = [0, parameters.p_value_plot_max];
            if parameters.significance_type == SigType.INCREASING && parameters.p_value_plot_max < 1
                coefficient_bounds = [parameters.p_value_plot_max, 1];
            end

            % Check if it's an edge chord plot, and if so, do we plot positive and negative separately
            if isfield(parameters, 'edge_chord_plot_method')
                obj.edge_plot_type = parameters.edge_chord_plot_method;
                if obj.edge_plot_type == EdgeChordPlotMethod.COEFF_SPLIT || obj.edge_plot_type == EdgeChordPlotMethod.COEFF_BASE_SPLIT
                    obj.split_plot = true;
                end
            end

            % Create the figure windows that all the plots will go in
            if obj.split_plot && chord_type == nla.PlotType.CHORD_EDGE
                plot_figure = nla.gfx.createFigure((obj.axis_width * 2) + obj.trimatrix_width - 100, obj.axis_width);
            else
                plot_figure = nla.gfx.createFigure(obj.axis_width + obj.trimatrix_width, obj.axis_width);
            end
            
            % Plot a standard chord plot
            if chord_type == nla.PlotType.CHORD
                figure_axis = axes(plot_figure, 'Units', 'pixels', 'Position', [obj.trimatrix_width, 0, obj.axis_width,...
                    obj.axis_width]);
                nla.gfx.hideAxes(figure_axis);

                insignificance = coefficient_bounds(2);
                if parameters.significance_type == SigType.INCREASING
                    insignificance = coefficient_bounds(1);
                end

                % thresholding below the "insignificance" value
                statistic_matrix = copy(parameters.statistic_plot_matrix);
                statistic_matrix.v(~parameters.significance_plot.v) = insignificance;

                chord_plotter = nla.gfx.chord.ChordPlot(obj.network_atlas, figure_axis, 500, statistic_matrix,...
                    'color_map', parameters.color_map, 'direction', parameters.significance_type, 'upper_limit',...
                    coefficient_bounds(2), 'lower_limit', coefficient_bounds(1), 'chord_type', chord_type);
                chord_plotter.drawChords();
            else
                % Plot edge chord
                obj.generateEdgeChordFigure(plot_figure, parameters, chord_type)
            end

            % Plot Trimatrix with the chord plots
            plotter = NoPermutationPlotter(obj.network_atlas);
            plotter.plotProbability(plot_figure, parameters, 25, obj.bottom_text_height);

            obj.generatePlotText(plot_figure, chord_type);
        end
    end

    methods (Access = protected)
        function generateEdgeChordFigure(obj, plot_figure, parameters, chord_type)
            % generateEdgeChordFigure generates the edge chord plotting
            import nla.gfx.EdgeChordPlotMethod nla.gfx.setTitle

            range_limit = std(obj.edge_test_result.coeff.v) * 5;
            coefficient_min = -range_limit;
            coefficient_max = range_limit;

            clipped_values = nla.TriMatrix(obj.network_atlas.numROIs(), nla.TriMatrixDiag.REMOVE_DIAGONAL);
            clipped_values.v = obj.edge_test_result.coeff.v;
            clipped_values.v(obj.edge_test_result.coeff.v > 0) = 0;
            clipped_values_positive = nla.TriMatrix(obj.network_atlas.numROIs(), nla.TriMatrixDiag.REMOVE_DIAGONAL);
            clipped_values_positive.v = obj.edge_test_result.coeff.v;
            clipped_values_positive.v(obj.edge_test_result.coeff.v < 0) = 0;

            color_map = turbo(1000);
            significance_type = nla.gfx.SigType.ABS_INCREASING;
            insignificance = 0; % This is basically the background for the plot
            % This is the title for the positive (or non-split) chord plot
            positive_title = sprintf("Edge-level correlation (P < %g) (Within Significant Net-Pair)",...
                obj.edge_test_result.prob_max);
            % This is the title for the negative chord plot
            negative_title = sprintf("Negative edge-level correlation (P < %g) (Within Significant Net-Pair)",...
                obj.edge_test_result.prob_max);

            % There are some settings that need to be changed depending on the specific type of edge plot
            switch obj.edge_plot_type
                case EdgeChordPlotMethod.COEFF
                    main_title = positive_title;

                case EdgeChordPlotMethod.COEFF_SPLIT
                    main_title = negative_title;
                    positive_main_title = positive_title;

                case EdgeChordPlotMethod.COEFF_BASE_SPLIT
                    coefficient_min = obj.edge_test_result.coeff_range(1);
                    coefficient_max = obj.edge_test_result.coeff_range(2);

                    main_title = negative_title;
                    positive_main_title = positive_title;

                case EdgeChordPlotMethod.COEFF_BASE
                    coefficient_min = obj.edge_test_result.coeff_range(1);
                    coefficient_max = obj.edge_test_result.coeff_range(2);

                    main_title = positive_title;

                otherwise
                    color_map_base = parula(1000);
                    color_map = flip(color_map_base(ceil(logspace(-3, 0, 1000) .* 1000), :));

                    clipped_values.v = obj.edge_test_result.prob.v;
                    significance_type = nla.gfx.SigType.DECREASING;
                    
                    coefficient_min = 0;
                    coefficient_max = obj.edge_test_result.prob_max;

                    insignificance = 1;
                    main_title = sprintf("Edge-level P-values (P < %g) (Within Significant Net-Pair)",...
                        obj.edge_test_result.prob_max);
            end

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

            plot_axis = axes(plot_figure, 'Units', 'pixels', 'Position', [obj.trimatrix_width, 0, obj.axis_width - 50,...
                obj.axis_width - 50]);
            nla.gfx.hideAxes(plot_axis);
            plot_axis.Visible = true;

            if obj.split_plot && chord_type == nla.PlotType.CHORD_EDGE && (...
                obj.edge_plot_type == EdgeChordPlotMethod.COEFF_SPLIT || obj.edge_plot_type == EdgeChordPlotMethod.COEFF_BASE_SPLIT...
            )
                positive_chord_plotter = nla.gfx.chord.ChordPlot(obj.network_atlas, plot_axis, 450, clipped_values_positive,...
                    'direction', significance_type, 'chord_type', chord_type, 'color_map', color_map, 'lower_limit',...
                    coefficient_min, 'upper_limit', coefficient_max);
                positive_chord_plotter.drawChords();
                setTitle(plot_axis, positive_main_title);

                % create another axis, I hate this naming but we can overwrite the old one
                plot_axis = axes(plot_figure, 'Units', 'pixels', 'Position',...
                    [obj.trimatrix_width + obj.axis_width - 100, 0 , obj.axis_width - 50, obj.axis_width - 50]);
                nla.gfx.hideAxes(plot_axis);
                plot_axis.Visible = true;
            end

            chord_plotter = nla.gfx.chord.ChordPlot(obj.network_atlas, plot_axis, 450, clipped_values, 'chord_type', chord_type,...
                'direction', significance_type, 'color_map', color_map, 'lower_limit', coefficient_min, 'upper_limit', coefficient_max);
            chord_plotter.drawChords();
            setTitle(plot_axis, main_title);

            colormap(plot_axis, color_map);
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
        end

        function generatePlotText(obj, plot_figure, chord_type)
            text_axis = axes(plot_figure, 'Units', 'pixels', 'Position', [55, obj.bottom_text_height + 15, 450, 75]);
            nla.gfx.hideAxes(text_axis);
            info_text = "Click any net-pair in the above plot to view its edge-level correlations.";
            if chord_type == nla.PlotType.CHORD_EDGE
                info_text = sprintf("%s\n\nChord plot:\nEach ROI is marked by a dot next to its corresponding network.\nROIs are placed in increasing order counter-clockwise, the first ROI in\na network being the most clockwise, the last being the most counter-\nclockwise.", info_text);
            end
            text(text_axis, 0, 0, info_text, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
        end
    end
end