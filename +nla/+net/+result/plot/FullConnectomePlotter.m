classdef FullConnectomePlotter < NoPermutationPlotter

    properties
        network_atlas
    end

    methods
        function obj = FullConnectomePlotter(network_atlas)
            if nargin > 0
                obj.network_atlas = network_atlas;
            end
        end

        function [w, h] = plotProbability(obj, plot_figure, parameters, x_coordinate, y_coordinate)
            % I know I don't need to define this here. I don't like it when the superclass methods just start showing up
            % Matlab's class organization is so hacked together, I just like to really show everything
            [w, h] = plotProbability@NoPermutationPlotter(obj, plot_figure, parameters, x_coordinate, y_coordinate);
        end

        function plotProbabilityHistogram(obj, axes, statistic_input, no_permutations_network_result, test_method,...
            parameters)
            import nla.HistBin

            empirical_fdr = parameters.empirical_fdr;
            empirical_fdr = cumsum(double(statistic_input) ./ sum(statistic_input));

            minimum_index = parameters.minimum_index;
            p_value_max = parameters.p_value_max;
            statistic_max = HistBin.EDGES(minimum_index);

            if (empirical_fdr(minimum_index) > p_value_max) && minimum_index > 1
                p_value_max = HistBin.EDGES(minimum_index - 1);
            end

            loglog(axes, HistBin.EDGES(2:end), empirical_fdr, "k");
            hold("on");
            loglog(axes, no_permutations_network_result, statistic_input.v, "ok");
            axis([min(no_permutations_network_result), 1, min(statistic_input.v), 1]);
            loglog(axes, axes.XLim, [p_value_max, p_value_max], "b");
            no_permutation_max = max(no_permutations_network_result);
            loglog(axes, [no_permutation_max, no_permutation_max], axes.YLim, "r");

            name_label = sprintf("%s P-values", test_method);
            nla.gfx.setTitle(axes, name_label);
            xlabel(axes, "Asymptotic");
            ylabel(axes, "Permutation-based P-value");
        end
    end
end