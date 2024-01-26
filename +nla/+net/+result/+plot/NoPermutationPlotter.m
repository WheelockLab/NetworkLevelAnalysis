classdef NoPermutationPlotter < handle

    properties
        network_atlas
    end

    methods
        function obj = NoPermutationPlotter(network_atlas)
            if nargin > 0
                obj.network_atlas = network_atlas;
            end
        end

        function [w, h] = plotProbability(obj, plot_figure, parameters, x_coordinate, y_coordinate)
            color_map = parameters.color_map;
            statistic_matrix = parameters.statistic_plot_matrix;
            p_value_max = parameters.p_value_plot_max;
            plot_label = parameters.name_label;
            significance_plot = parameters.significance_plot;
            clickCallback = parameters.callback;
            
            [w, h] = nla.gfx.drawMatrixOrg(plot_figure, x_coordinate, y_coordinate, plot_label, statistic_matrix, 0,...
                p_value_max, obj.network_atlas.nets, nla.gfx.FigSize.SMALL, nla.gfx.FigMargins.WHITESPACE, false, true,...
                color_map, significance_plot, false, clickCallback);
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

            xlabel(axes, "Number of ROI pairs within network pair");
            ylabel(axes, "-log_1_0(Asymptotic P-value)");
            setTitle(axes, plot_title);
            second_title = sprintf('Check if P-values correlate with net-pair size\n(corr: p = %.2f, r = %.2f)', p_values, rho);
            setTitle(axes, second_title, true);
            lims = ylim(axes);
            ylim(axes, [0 lims(2)]);
        end
    end
end