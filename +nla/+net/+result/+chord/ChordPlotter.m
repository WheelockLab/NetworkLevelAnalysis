classdef ChordPlotter < handle
% CHORDPLOTTER Draws network test results in Chord Figures

    properties (Constant)
        axis_width = 750;
        trimatrix_width = 500;
        bottom_text_height = 250;
    end

    properties
        network_atlas
        edge_test_result
    end

    methods
        function obj = ChordPlotter(network_atlas, edge_test_result)
            if nargin > 0
                obj.network_atlas = network_atlas;
            end
            if nargin > 1
                obj.edge_test_result = edge_test_result;
            end
        end

        function generateChordFigure(obj, parameters, chord_type)
            import nla.gfx.SigType nla.gfx.drawChord

            coefficient_bounds = [0, parameters.p_value_plot_max];
            if parameters.significance_type == SigType.INCREASING && parameters.p_value_plot_max < 1
                coefficient_bounds = [parameters.p_value_plot_max, 1];
            end

            if chord_type == nla.PlotType.CHORD
                plot_figure = nla.gfx.createFigure(obj.axis_width + obj.trimatrix_width, obj.axis_width);

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

                drawChord(figure_axis, 500, obj.network_atlas, statistic_matrix, parameters.color_map,...
                    parameters.significance_type, chord_type, coefficient_bounds(1), coefficient_bounds(2));
            else
                obj.generateEdgeChordFigure(parameters, chord_type, obj.edge_test_result)
            end
        end
    end

    methods (Access = protected)
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

            range_limit = std(obj.edge_test_result.coeff.v) * 5;
            coefficient_min = -range_limit;
            coefficient_max = range_limit;

            clipped_values = nla.TriMatrix(obj.network_atlas.numROIs(), nla.TriMatrixDiag.REMOVE_DIAGONAL);
            clipped_values.v = obj.edge_test_result.coeff.v;
            clipped_values.v(obj.edge_test_result.coeff.v > 0) = 0;
            clipped_values_positive = nla.TriMatrix(obj.network_atlas.numROIs(), nla.TriMatrixDiag.REMOVE_DIAGONAL);
            clipped_values_positive.v = obj.edge_test_result.coeff.v;
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
                    main_title = sprintf("Edge-level P-values (P < %g) (Within Significant Net-Pair)", obj.edge_test_result.prob_max);
            end

            for network1 = 1:obj.network_atlas.numNets()
                for network2 = 1:network1
                    if ~parameters.significance_plot.get(network1, network2)
                        clipped_values.set(obj.network_atlas.nets(network1).indexes, obj.network_atlas(network2).indexes,...
                            insignificance);
                        if split_plot
                            clipped_values_positive.set(obj.network_atlas.nets(network1).indexes, obj.network_atlas(network2).indexes,...
                            insignificance);
                        end
                    end
                end
            end

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
                nla.gfx.hideAxes(plot_axis);
                plot_axis.Visible = true;
            end

            drawChord(plot_axis, 450, obj.network_atlas, color_map, significance_type, chord_type, coefficient_min, coefficient_max);
            setTitle(plot_axis, main_title);

            colormap(plot_axis, color_map);
            color_bar = colorbar(plot_axis);
            color_bar.Units = 'pixels';
            color_bar.Loaction = 'east';
            color_bar.Position = [color_bar.Position(1) + 25, color_bar.Position(2) + 100, color_bar.Position(3),...
                color_bar.Position(4) - 200];

            number_ticks = 10;
            ticks = [0:number_ticks];
            color_bar.Ticks = double(tickts) ./ number_ticks;

            labels = {};
            for tick = ticks
                labels{tick + 1} = sprintf("%.2g", coefficient_min + (tick * ((coefficient_max - coefficient_min) / number_ticks)));
            end
            color_bar.TickLabels = labels;
        end
    end
end