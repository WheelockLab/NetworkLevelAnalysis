classdef NetworkTestPlot < handle

    properties
        network_atlas
        network_test_result
        ranking_method
        x_position
        y_position
    end

    properties (Dependent)
        is_noncorrelation_input
    end

    methods

        function obj = NetworkTestPlot(network_test_result, network_atlas, ranking_method)
            
            test_plot_parser = inputParser;
            addRequired(test_plot_parser, 'network_test_result');
            addRequired(test_plot_parser, 'network_atlas');
            addRequired(test_plot_parser, 'ranking_method');

            validNumberInput = @(x) isnumeric(x) && isscalar(x);
            addParameter(test_plot_parser, 'x_position', 300, validNumberInput);
            addParameter(test_plot_parser, 'y_position', 0, validNumberInput);
        
            parse(test_plot_parser, network_test_result, network_atlas, ranking_method, varargin{:});
            properties = {'network_test_result', 'network_atlas', 'ranking_method', 'x_position', 'y_position'};
            for property = properties
                obj.(property{1}) = test_plot_parser.Results.(property{1});
            end
        end

        function value = get.is_noncorrelation_input(obj)
            value = obj.network_test_result.is_noncorrelation_input;
        end
    end

    methods (Access = protected)

        function p_value = choosePlottingMethod(obj, test_options)
            
            p_value = "p_value";
            if test_options == nla.gfx.ProbPlotMethod.STATISTIC
                p_value = strcat("statistic_", p_value);
            end
            if ~obj.network_test_result.is_noncorrelation_input && obj.ranking_method == "within_network_pair"
                p_value = strcat("single_sample_", p_value);
            end
        end

        function title = getPlotTitle(obj, test_options)

            switch obj.ranking_method
                case "no_permutations"
                    title = sprintf("Non-permuted Method\nNon-permuted Significance");
                case "full_connectome"
                    title = sprintf("Full Connectome Method\nNetwork vs. Connectome Significance");
                case "within_network_pair"
                    title = sprintf("Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair");
            end
        end

        function drawFigure(obj, test_options)

            plot_figure = nla.gfx.createFigure(500, 800);
            plot_data = obj.network_test_result.(obj.ranking_method).(obj.choosePlottingMethod(test_options))
            matrix_plot = nla.gfx.plots.MatrixPlot(plot_figure, obj.getPlotTitle(test_options), plot_data, obj.network_atlas.nets, nla.gfx.FigSize.SMALL, 'y_position', obj.y_position + 300);
            panel = uipanel(plot_figure, 'Units', 'pixels', 'Position', [10 10 480 300]);
            
        end
    end
end