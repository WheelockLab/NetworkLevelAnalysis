classdef DiagnosticPlot < handle

    properties
        edge_test_options
        network_test_options
        edge_test_result
        network_atlas
        networkTestResult
    end

    methods
        function obj = DiagnosticPlot(edge_test_options, network_test_options, edge_test_result, network_atlas, networkTestResult)
            diagnostic_plot_parser = inputParser;
            addRequired(diagnostic_plot_parser, 'edge_test_options');
            addRequired(diagnostic_plot_parser, 'network_test_options');
            addRequired(diagnostic_plot_parser, 'edge_test_result');
            addRequired(diagnostic_plot_parser, 'network_atlas');
            addRequired(diagnostic_plot_parser, 'networkTestResult');

            parse(diagnostic_plot_parser, edge_test_options, network_test_options, edge_test_result, network_atlas, networkTestResult);
            properties = {'edge_test_options', "network_test_options", "edge_test_result", "network_atlas", "networkTestResult"};
            for property = properties
                obj.(property{1}) = diagnostic_plot_parser.Results.(property{1});
            end
        end

        function displayPlots(obj, ranking_algorithm)

            p_value = obj.choosePlottingStatistic(ranking_algorithm);
            
            plot_parameters = nla.net.result.NetworkResultPlotParameter(...
                obj.networkTestResult, obj.network_atlas, obj.network_test_options...
            );
            vs_network_size_parameters = plot_parameters.plotProbabilityVsNetworkSize(ranking_algorithm, p_value);
            no_permutations_vs_network_parameters = plot_parameters.plotProbabilityVsNetworkSize(...
                "no_permutations", p_value...
            );

            non_permuted_title = sprintf("Non-permuted P-values vs.\nNetwork-Pair Size");
            permuted_title = sprintf("Permuted P-values vs Network-Pair Size");

            plotter = nla.net.result.plot.PermutationTestPlotter(obj.network_atlas);
            if isequal(ranking_algorithm, "no_permutations")
                nla.gfx.createFigure(500, 500);
                plotter.plotProbabilityVsNetworkSize(vs_network_size_parameters, subplot(1, 1, 1), non_permuted_title);
                return
            end
            nla.gfx.createFigure(1200, 500);

            p_value_histogram = obj.networkTestResult.createHistogram(p_value);
            plotter.plotProbabilityHistogram(...
                subplot(1, 3, 1), p_value_histogram, obj.networkTestResult.full_connectome.statistic_p_value.v,...
                obj.networkTestResult.permutation_results.p_value_permutations.v(:, 1),...
                obj.networkTestResult.test_display_name, obj.network_test_options.prob_max...
            );
            plotter.plotProbabilityVsNetworkSize(no_permutations_vs_network_parameters, subplot(1, 3, 2), non_permuted_title);
            plotter.plotProbabilityVsNetworkSize(vs_network_size_parameters, subplot(1, 3, 3), permuted_title);
        end
    end

    methods (Access = private)
        function p_value = choosePlottingStatistic(obj, test_method)
            p_value = "p_value";
            if obj.network_test_options == nla.gfx.ProbPlotMethod.STATISTIC
                p_value = strcat("statistic_", p_value);
            end
            if ~obj.networkTestResult.is_noncorrelation_input && test_method == "within_network_pair"
                p_value = strcat("single_sample_", p_value);
            end
        end
    end
end