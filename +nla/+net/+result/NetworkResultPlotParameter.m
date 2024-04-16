classdef NetworkResultPlotParameter < handle
% NETWORKRESULTPLOTParamter Creates parameters and plots for network test results

    properties
        network_test_results
        network_atlas
        updated_test_options
    end

    properties (Dependent)
        test_methods
        noncorrelation_input_tests
        number_of_networks
    end

    properties (Constant)
        default_discrete_colors = 1000
    end

    methods
        function obj = NetworkResultPlotParameter(network_test_results, network_atlas, updated_test_options)
            if nargin > 0
                obj.network_test_results = network_test_results;
                obj.network_atlas = network_atlas;
                obj.updated_test_options = updated_test_options;
            end
        end

        function result = plotProbabilityParameters(obj, edge_test_options, edge_test_result, test_method, plot_statistic,...
                plot_title, fdr_correction, significance_filter)
            % plot_title - this will be a string
            % plot_statistic - this is the stat that will be plotted, string
            % significance filter - this will be a boolean or some sort of object (like Cohen's D > D-value)
            % fdr_correction - a struct of fdr_correction (found in nla.net.mcc) or None
            % test_method - 'no permutations', 'within network pair', 'full connectome'

            import nla.TriMatrix nla.TriMatrixDiag
            % We're going to use a default filter here
            if isequal(significance_filter, false)
                significance_filter = TriMatrix(obj.number_of_networks, "logical", TriMatrixDiag.KEEP_DIAGONAL);
                significance_filter.v = true(numel(significance_filter.v), 1);
            end

            % Adding on to the plot title if it's a -log10 plot
            if obj.updated_test_options.prob_plot_method == nla.gfx.ProbPlotMethod.NEG_LOG_10
                plot_title = sprintf("%s (-log_1_0(P))", plot_title);
            end

            % Grab the data from the NetworkTestResult object
            statistic_input = obj.getStatsFromMethodAndName(test_method, plot_statistic);

            % Get the scale max and the labels
            p_value_max = fdr_correction.correct(obj.network_atlas, obj.updated_test_options, statistic_input);
            p_value_breakdown_label = fdr_correction.createLabel(obj.network_atlas, obj.updated_test_options,...
                statistic_input);

            name_label = sprintf("%s %s\nP < %.2g (%s)", obj.network_test_results.test_display_name, plot_title,...
                p_value_max, p_value_breakdown_label);

            % Filtering if there's a filter provided 
            significance_plot = TriMatrix(obj.number_of_networks, "logical", TriMatrixDiag.KEEP_DIAGONAL);
            significance_plot.v = (statistic_input.v < p_value_max) & significance_filter.v;

            % scale values very slightly for display so numbers just below
            % the threshold don't show up white but marked significant
            statistic_input_scaled = TriMatrix(obj.number_of_networks, "double", TriMatrixDiag.KEEP_DIAGONAL);
            statistic_input_scaled.v = statistic_input.v .* (obj.default_discrete_colors / (obj.default_discrete_colors + 1));

            % default values for plotting
            statistic_plot_matrix = statistic_input_scaled;
            p_value_plot_max = p_value_max;
            significance_type = nla.gfx.SigType.DECREASING;
            % determine colormap and operate on values if it's -log10
            switch obj.updated_test_options.prob_plot_method
                case nla.gfx.ProbPlotMethod.LOG
                    color_map = nla.net.result.NetworkResultPlotParameter.getLogColormap(obj.default_discrete_colors,...
                        statistic_input, p_value_max);
                % Here we take a -log10 and change the maximum value to show on the plot
                case nla.gfx.ProbPlotMethod.NEG_LOG_10
                    color_map = parula(obj.default_discrete_colors);

                    statistic_matrix = nla.TriMatrix(obj.number_of_networks, "double", nla.TriMatrixDiag.KEEP_DIAGONAL);
                    statistic_matrix.v = -log10(statistic_input.v);
                    statistic_plot_matrix = statistic_matrix;
                    if strcmp(test_method, "full_connectome") || strcmp(test_method, "within_network_pair")
                        p_value_plot_max = 2;
                    else
                        p_value_plot_max = 40;
                    end
                    significance_type = nla.gfx.SigType.INCREASING;
                otherwise
                    color_map = nla.net.result.NetworkResultPlotParameter.getColormap(obj.default_discrete_colors,...
                        p_value_max);
            end

            % callback function for brain image. 
            % Because of the way the plotting is done in MatrixPlot, this function can have only two inputs. Because
            % edge_test_options and edge_test_result are "global", this needs to be an internal function and not a method
            function brainFigureButtonCallback(network1, network2)
                wait_text = sprintf("Generating %s - %s network-pair brain plot", obj.network_atlas.nets(network1).name,...
                    obj.network_atlas.nets(network2).name);
                wait_popup = waitbar(0.05, wait_text);
                nla.gfx.drawBrainVis(edge_test_options, obj.updated_test_options, obj.network_atlas,...
                    nla.gfx.MeshType.STD, 0.25, 3, true, edge_test_result, network1, network2,...
                    any(strcmp(obj.noncorrelation_input_tests, obj.network_test_results.test_name)));
                waitbar(0.95);
                close(wait_popup);
            end

            % Return a struct. It's either this or a long array. Since matlab doesn't do dictionaries, we're doing this
            result = struct();
            result.color_map = color_map;
            result.statistic_plot_matrix = statistic_plot_matrix;
            result.p_value_plot_max = p_value_plot_max;
            result.name_label = name_label;
            result.significance_plot = significance_plot;
            result.callback = @brainFigureButtonCallback;
            result.significance_type = significance_type;
            result.plot_scale = obj.updated_test_options.prob_plot_method;
        end

        function result = plotProbabilityVsNetworkSize(obj, test_method, plot_statistic)
            % Two convience methods
            network_size = obj.getNetworkSizes();
            statistic_input = obj.getStatsFromMethodAndName(test_method, plot_statistic);

            negative_log10_statistics = -log10(statistic_input.v);

            least_squares_line_coefficients = polyfit(network_size.v, negative_log10_statistics, 1);

            [rho, p_values] = corr(network_size.v, negative_log10_statistics);

            result = struct();
            result.least_squares_line_coefficients = least_squares_line_coefficients;
            result.negative_log10_statistics = negative_log10_statistics;
            result.network_size = network_size;
            result.rho = rho;
            result.p_values = p_values;
        end

        function value = get.test_methods(obj)
            value = obj.network_test_results.test_methods;
        end

        function value = get.noncorrelation_input_tests(obj)
            value = obj.network_test_results.noncorrelation_input_tests;
        end

        function value = get.number_of_networks(obj)
            value = obj.network_atlas.numNets();
        end
    end

    methods (Access = protected)
        function network_size = getNetworkSizes(obj)
            import nla.TriMatrix nla.TriMatrixDiag
            ROI_pairs = TriMatrix(obj.network_atlas.numROIs(), "logical");
            network_size = TriMatrix(obj.number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            for row = 1:obj.number_of_networks
                for column = 1:row
                    network_size.set(row, column, numel(ROI_pairs.get(obj.network_atlas.nets(row).indexes,...
                        obj.network_atlas.nets(column).indexes)));
                end
            end
        end

        function statistic = getStatsFromMethodAndName(obj, test_method, plot_statistic)
            % combining the method and stat name to get the data. With a fail safe for forgetting 'single_sample'
            if test_method == "within_network_pair" && ~startsWith(plot_statistic, "single_sample")
                plot_statistic = strcat("single_sample_", plot_statistic);
            end
            statistic = obj.network_test_results.(test_method).(plot_statistic);
        end
    end

    methods(Static)
        function color_map = getLogColormap(default_discrete_colors, probabilities_input, p_value_max, color_map)
            log_minimum = log10(min(nonzeros(probabilities_input.v)));
            log_minimum = max([-40, log_minimum]);

            color_map_base = parula(default_discrete_colors);
            if nargin > 3
                color_map_name = str2func(lower(color_map));
                color_map_base = color_map_name(default_discrete_colors);
            end

            % Relevant for BenjaminYekutieli/BenjaminHochberg fdr correction
            default_color_map = [1 1 1];
            if p_value_max ~= 0
                color_map = flip(color_map_base(ceil(logspace(log_minimum, 0, default_discrete_colors) .*...
                    default_discrete_colors), :));
                color_map = [color_map; default_color_map];
            else
                color_map = default_color_map;
            end
        end

        function color_map = getColormap(default_discrete_colors, p_value_max, color_map)
            color_map_base = parula(default_discrete_colors);
            if nargin > 2
                color_map_name = str2func(lower(color_map));
                color_map_base = color_map_name(default_discrete_colors);
            end

            default_color_map = [1 1 1];
            if p_value_max == 0
                color_map = default_color_map;
            else
                color_map = flip(color_map_base);
                color_map = [color_map; default_color_map];
            end
        end
    end
end