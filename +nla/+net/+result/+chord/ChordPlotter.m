classdef ChordPlotter < handle
% CHORDPLOTTER Draws network test results in Chord Figures
<<<<<<< HEAD
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
        edge_plot_type = "nla.gfx.EdgeChordPlotMethod.PROB" % Default chord type for edges
=======

    properties (Constant)
        axis_width = 750;
        trimatrix_width = 500;
        bottom_text_height = 250;
    end

    properties
        network_atlas
        edge_test_result
>>>>>>> added chord plotter and trying to integrate it into no permutations
    end

    methods
        function obj = ChordPlotter(network_atlas, edge_test_result)
<<<<<<< HEAD
            % Constructor. Inputs = network_atlas, edge_test_result
            % Output = ChordPlotter object
=======
>>>>>>> added chord plotter and trying to integrate it into no permutations
            if nargin > 0
                obj.network_atlas = network_atlas;
            end
            if nargin > 1
                obj.edge_test_result = edge_test_result;
            end
        end

        function generateChordFigure(obj, parameters, chord_type)
<<<<<<< HEAD
            % generateChordFigure plots chords for a network test
            import nla.gfx.SigType nla.net.result.plot.PermutationTestPlotter nla.gfx.EdgeChordPlotMethod nla.gfx.setTitle
=======
            import nla.gfx.SigType nla.gfx.drawChord
>>>>>>> added chord plotter and trying to integrate it into no permutations

            coefficient_bounds = [0, parameters.p_value_plot_max];
            if parameters.significance_type == SigType.INCREASING && parameters.p_value_plot_max < 1
                coefficient_bounds = [parameters.p_value_plot_max, 1];
            end

<<<<<<< HEAD
            % Check if it's an edge chord plot, and if so, do we plot positive and negative separately
            if isfield(parameters, 'edge_chord_plot_method')
                obj.edge_plot_type = parameters.edge_chord_plot_method;
                if obj.edge_plot_type == "nla.gfx/EdgeChordPlotMethod.COEFF_SPLIT" || obj.edge_plot_type == "nla.gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT"
                    obj.split_plot = true;
                end
            end

            % Create the figure windows that all the plots will go in
            if obj.split_plot && chord_type == "nla.PlotType.CHORD_EDGE"
                plot_figure = nla.gfx.createFigure((obj.axis_width * 2), obj.axis_width);
            else
                plot_figure = nla.gfx.createFigure(obj.axis_width , obj.axis_width);
            end
            
            % Plot a standard chord plot
            if chord_type == "nla.PlotType.CHORD"
                figure_axis = axes(plot_figure, 'Units', 'pixels', 'Position', [0, 0, obj.axis_width,...
=======
            if chord_type == nla.PlotType.CHORD
                plot_figure = nla.gfx.createFigure(obj.axis_width + obj.trimatrix_width, obj.axis_width);

                figure_axis = axes(plot_figure, 'Units', 'pixels', 'Position', [obj.trimatrix_width, 0, obj.axis_width,...
>>>>>>> added chord plotter and trying to integrate it into no permutations
                    obj.axis_width]);
                nla.gfx.hideAxes(figure_axis);

                insignificance = coefficient_bounds(2);
<<<<<<< HEAD
                if parameters.significance_type == "nla.gfx.SigType.INCREASING"
=======
                if parameters.significance_type == SigType.INCREASING
>>>>>>> added chord plotter and trying to integrate it into no permutations
                    insignificance = coefficient_bounds(1);
                end

                % thresholding below the "insignificance" value
                statistic_matrix = copy(parameters.statistic_plot_matrix);
                statistic_matrix.v(~parameters.significance_plot.v) = insignificance;

<<<<<<< HEAD
                chord_plotter = nla.gfx.chord.ChordPlot(obj.network_atlas, figure_axis, 500, statistic_matrix,...
                    'color_map', parameters.color_map, 'direction', parameters.significance_type, 'upper_limit',...
                    coefficient_bounds(2), 'lower_limit', coefficient_bounds(1), 'chord_type', chord_type);
                chord_plotter.drawChords();
                setTitle(figure_axis, parameters.name_label)
            else
                % Plot edge chord
                obj.generateEdgeChordFigure(plot_figure, parameters, chord_type)
            end


=======
                drawChord(figure_axis, 500, obj.network_atlas, statistic_matrix, parameters.color_map,...
                    parameters.significance_type, chord_type, coefficient_bounds(1), coefficient_bounds(2));
            else
                obj.generateEdgeChordFigure(parameters, chord_type, obj.edge_test_result)
            end
>>>>>>> added chord plotter and trying to integrate it into no permutations
        end
    end

    methods (Access = protected)
<<<<<<< HEAD
        function generateEdgeChordFigure(obj, plot_figure, parameters, chord_type)
            % generateEdgeChordFigure generates the edge chord plotting
            import nla.gfx.EdgeChordPlotMethod nla.gfx.setTitle
=======
        function generateEdgeChordFigure(obj, parameters, chord_type)
            import nla.gfx.EdgeChordPlotMethod nla.gfx.drawChord nla.gfx.setTitle

            edge_plot_type = EdgeChordPlotMethod.PROB;
            split_plot = false;
            if isfield(parameters, 'edge_chord_plot_method')
                edge_plot_type = parameters.edge_chord_plot_method;
                if edge_plot_type == EdgeChordPlotMethod.COEFF_SPLIT || edge_plot_type == EdgeChordPlotMethod.COEFF_BASE_SPLIT
                    split_plot = true;
                end
            end
>>>>>>> added chord plotter and trying to integrate it into no permutations

            range_limit = std(obj.edge_test_result.coeff.v) * 5;
            coefficient_min = -range_limit;
            coefficient_max = range_limit;

            clipped_values = nla.TriMatrix(obj.network_atlas.numROIs(), nla.TriMatrixDiag.REMOVE_DIAGONAL);
            clipped_values.v = obj.edge_test_result.coeff.v;
            clipped_values.v(obj.edge_test_result.coeff.v > 0) = 0;
            clipped_values_positive = nla.TriMatrix(obj.network_atlas.numROIs(), nla.TriMatrixDiag.REMOVE_DIAGONAL);
            clipped_values_positive.v = obj.edge_test_result.coeff.v;
<<<<<<< HEAD
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

                case "nla.gfx.EdgeChordPlotMethod.COEFF_SPLIT"
                    main_title = negative_title;
                    positive_main_title = positive_title;

                case "nla.gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT"
=======
            clipped_values_positive.v(obj.edge_test_result.v < 0) = 0;

            color_map = turbo(1000);
            significance_type = nla.gfx.SigType.ABS_INCREASING;
            insignificance = 0;
            positive_title = sprintf("Edge-level correlation (P < %g) (Within Significant Net-Pair)",...
                obj.edge_test_result.prob_max);
            negative_title = sprintf("Negative edge-level correlation (P < %g) (Within Significant Net-Pair)",...
                obj.edge_test_result.prob_max);

            switch edge_plot_type
                case EdgeChordPlotMethod.COEFF
                    main_title = positive_title;

                case EdgeChordPlotMethod.COEFF_SPLIT
                    main_title = negative_title;
                    positive_main_title = positive_title;

                case EdgeChordPlotMethod.COEFF_BASE_SPLIT
>>>>>>> added chord plotter and trying to integrate it into no permutations
                    coefficient_min = obj.edge_test_result.coeff_range(1);
                    coefficient_max = obj.edge_test_result.coeff_range(2);

                    main_title = negative_title;
                    positive_main_title = positive_title;

<<<<<<< HEAD
                case "nla.gfx.edgeChordPlotMethod.COEFF_BASE"
=======
                case EdgeChordPlotMethod.COEFF_BASE
>>>>>>> added chord plotter and trying to integrate it into no permutations
                    coefficient_min = obj.edge_test_result.coeff_range(1);
                    coefficient_max = obj.edge_test_result.coeff_range(2);

                    main_title = positive_title;

                otherwise
                    color_map_base = parula(1000);
                    color_map = flip(color_map_base(ceil(logspace(-3, 0, 1000) .* 1000), :));

                    clipped_values.v = obj.edge_test_result.prob.v;
<<<<<<< HEAD
                    significance_type = "nla.gfx.SigType.DECREASING";
=======
                    significance_type = nla.gfx.SigType.DECREASING;
>>>>>>> added chord plotter and trying to integrate it into no permutations
                    
                    coefficient_min = 0;
                    coefficient_max = obj.edge_test_result.prob_max;

                    insignificance = 1;
<<<<<<< HEAD
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
=======
                    main_title = sprintf("Edge-level P-values (P < %g) (Within Significant Net-Pair)", obj.edge_test_result.prob_max);
            end

            for network1 = 1:obj.network_atlas.numNets()
                for network2 = 1:network1
                    if ~parameters.significance_plot.get(network1, network2)
                        clipped_values.set(obj.network_atlas.nets(network1).indexes, obj.network_atlas(network2).indexes,...
                            insignificance);
                        if split_plot
                            clipped_values_positive.set(obj.network_atlas.nets(network1).indexes, obj.network_atlas(network2).indexes,...
>>>>>>> added chord plotter and trying to integrate it into no permutations
                            insignificance);
                        end
                    end
                end
            end

<<<<<<< HEAD
            plot_axis = axes(plot_figure, 'Units', 'pixels', 'Position', [0, 0, obj.axis_width - 50,...
                obj.axis_width - 50]);
            nla.gfx.hideAxes(plot_axis);
            plot_axis.Visible = true;

            if obj.split_plot && chord_type == "nla.PlotType.CHORD_EDGE" && (...
                obj.edge_plot_type == "nla.gfx.EdgeChordPlotMethod.COEFF_SPLIT" || obj.edge_plot_type == "nla.gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT"...
            )
                positive_chord_plotter = nla.gfx.chord.ChordPlot(obj.network_atlas, plot_axis, 450, clipped_values_positive,...
                    'direction', significance_type, 'chord_type', chord_type, 'color_map', color_map, 'lower_limit',...
                    coefficient_min, 'upper_limit', coefficient_max);
                positive_chord_plotter.drawChords();
                setTitle(plot_axis, positive_main_title);

                % create another axis, I hate this naming but we can overwrite the old one
                plot_axis = axes(plot_figure, 'Units', 'pixels', 'Position',...
                    [obj.axis_width - 100, 0 , obj.axis_width - 50, obj.axis_width - 50]);
=======
            if split_plot
                plot_figure = nla.gfx.createFigure((obj.axis_width * 2) + obj.trimat_width - 100, obj.axis_width);
            else
                plot_figure = nla.gfx.createFigure(obj.axis_width + obj.trimat_width, obj.axis_width);
            end

            plot_axis = axes(plot_figure, 'Units', 'pixels', 'Position',...
                [obj.trimatrix_width, 0, obj.axis_width - 50, obj.axis_width - 50]);
            nla.gfx.hideAxes(plot_axis);
            plot_axis.Visible = true;

            if split_plot
                drawChord(plot_axis, 450, obj.network_atlas, clipped_values_positive, color_map, significance_type,...
                    chord_type, coefficient_min, coefficient_max);
                setTitle(plot_axis, positive_main_title);

                % create another axis, I hate this naming but we can overwrite the old one
                plot_axis = axes(plot_figure, 'Units', 'pixes', 'Position',...
                    [obj.trimat_width + obj.axis_width - 100, 0 , obj.axis_width - 50, obj.axis_width - 50]);
>>>>>>> added chord plotter and trying to integrate it into no permutations
                nla.gfx.hideAxes(plot_axis);
                plot_axis.Visible = true;
            end

<<<<<<< HEAD
            chord_plotter = nla.gfx.chord.ChordPlot(obj.network_atlas, plot_axis, 450, clipped_values, 'chord_type', chord_type,...
                'direction', significance_type, 'color_map', color_map, 'lower_limit', coefficient_min, 'upper_limit', coefficient_max);
            chord_plotter.drawChords();
=======
            drawChord(plot_axis, 450, obj.network_atlas, color_map, significance_type, chord_type, coefficient_min, coefficient_max);
>>>>>>> added chord plotter and trying to integrate it into no permutations
            setTitle(plot_axis, main_title);

            colormap(plot_axis, color_map);
            color_bar = colorbar(plot_axis);
            color_bar.Units = 'pixels';
<<<<<<< HEAD
            color_bar.Location = 'east';
=======
            color_bar.Loaction = 'east';
>>>>>>> added chord plotter and trying to integrate it into no permutations
            color_bar.Position = [color_bar.Position(1) + 25, color_bar.Position(2) + 100, color_bar.Position(3),...
                color_bar.Position(4) - 200];

            number_ticks = 10;
            ticks = [0:number_ticks];
<<<<<<< HEAD
            color_bar.Ticks = double(ticks) ./ number_ticks;
=======
            color_bar.Ticks = double(tickts) ./ number_ticks;
>>>>>>> added chord plotter and trying to integrate it into no permutations

            labels = {};
            for tick = ticks
                labels{tick + 1} = sprintf("%.2g", coefficient_min + (tick * ((coefficient_max - coefficient_min) / number_ticks)));
            end
            color_bar.TickLabels = labels;
        end
    end
end