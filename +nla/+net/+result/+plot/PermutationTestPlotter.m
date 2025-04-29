classdef PermutationTestPlotter < handle

    properties
        network_atlas
    end

    methods
        function obj = PermutationTestPlotter(network_atlas)
            if nargin > 0
                obj.network_atlas = network_atlas;
            end
        end

        function [w, h, matrix_plot] = plotProbability(obj, plot_figure, parameters, x_coordinate, y_coordinate)
            color_map = parameters.color_map;
            statistic_matrix = parameters.statistic_plot_matrix;
            p_value_max = parameters.p_value_plot_max;
            plot_label = parameters.name_label;
            significance_plot = parameters.significance_plot;
            clickCallback = parameters.callback;
            plot_scale = parameters.plot_scale;
            
            matrix_plot = nla.gfx.plots.MatrixPlot(plot_figure, plot_label, statistic_matrix, obj.network_atlas.nets,...
                nla.gfx.FigSize.SMALL, 'x_position', x_coordinate, 'y_position', y_coordinate, 'lower_limit', 0,...
                'upper_limit', p_value_max, 'color_map', color_map, 'network_clicked_callback', clickCallback,...
                'marked_networks', significance_plot, 'plot_scale', plot_scale, 'p_value_max', p_value_max);
            matrix_plot.displayImage();
            w = matrix_plot.image_dimensions("image_width");
            h = matrix_plot.image_dimensions("image_height");
        end

        function plotProbabilityVsNetworkSize(obj, parameters, axes, plot_title)
            import nla.gfx.setTitle

            network_size = parameters.network_size;
            least_squares_line_coefficients = parameters.least_squares_line_coefficients;
            negative_log10_statistics = parameters.negative_log10_statistics;
            rho = parameters.rho;
            p_values = parameters.p_values;

            % p_values vs network-pair size
            plot(network_size.v, negative_log10_statistics, "ok");

            % least-squares regression line
            least_squares_line_x = linspace(axes.XLim(1), axes.XLim(2), 2);
            least_squares_line_y = polyval(least_squares_line_coefficients, least_squares_line_x);
            hold("on");
            plot(least_squares_line_x, least_squares_line_y, "r");

            xlabel(axes, sprintf("Number of ROI pairs\nwithin network pair"));
            ylabel(axes, "-log_1_0(Asymptotic P-value)");
            setTitle(axes, plot_title);
            second_title = sprintf('Check if P-values correlate with\nnet-pair size (corr: p = %.2f, r = %.2f)', p_values, rho);
            setTitle(axes, second_title, true);
            lims = ylim(axes);
            if lims(2) < 0
                ylim(axes, [lims(2) 0]);
            else
                ylim(axes, [0 lims(2)]);
            end
        end

        function plotProbabilityHistogram(obj, axes, histogram_data, statistic_input, no_permutations_network_result, test_method,...
            probability_max)
            import nla.HistBin
            
            empirical_fdr = cumsum(double(histogram_data) ./ sum(histogram_data));

            [~, minimum_index] = min(abs(probability_max - empirical_fdr));

            statistic_max = HistBin.EDGES(minimum_index);

            if (empirical_fdr(minimum_index) > probability_max) && minimum_index > 1
                statistic_max = HistBin.EDGES(minimum_index - 1);
            end
            loglog(axes, HistBin.EDGES(2:end), empirical_fdr, "k");
            hold("on");
            loglog(axes, no_permutations_network_result, statistic_input, "ok");
            axis([min(no_permutations_network_result), 1, min(statistic_input), 1]);
            loglog(axes, axes.XLim, [probability_max, probability_max], "b");
            loglog(axes, [statistic_max, statistic_max], axes.YLim, "r");

            name_label = sprintf("%s P-values", test_method);
            nla.gfx.setTitle(axes, name_label);
            xlabel(axes, "Asymptotic");
            ylabel(axes, "Permutation-based P-value");
        end
    end
end