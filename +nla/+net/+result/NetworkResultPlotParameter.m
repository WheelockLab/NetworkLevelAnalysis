classdef NetworkResultPlotParameter < handle
% NETWORKRESULTPLOTParamter Creates parameters and plots for network test results

    properties
        network_test_results
        network_atlas
    end

    properties (Dependent)
        test_methods
        significance_test_names
        number_of_networks
    end

    properties (Constant)
        default_discrete_colors = 1000
    end

    methods
        function obj = NetworkResultPlotParameter(network_test_results, network_atlas)
            if nargin > 0
                obj.network_test_results = network_test_results;
                obj.network_atlas = network_atlas;
            end
        end

        function result = plotProbabilityParameters(obj, edge_test_options, edge_test_result, test_method, plot_statistic,...
                plot_title, fdr_correction, significance_filter)
            % plot_title - this will be a string
            % significance filter - this will be a boolean or some sort of object/struct filter
            % fdr_correction - a struct of fdr_correction (found in nla.net.mcc)
            % test_method - 'no permutations', 'within network pair', 'full connectome'

            import nla.TriMatrix nla.TriMatrixDiag

            % We're going to use a default filter here
            if nargin < 4
                significance_filter = TriMatrix(obj.number_of_networks, "logical", TriMatrixDiag.KEEP_DIAGONAL);
                significance_filter.v = true(numel(significance_filter.v), 1);
            end

            % Adding on to the plot title if it's a -log10 plot
            if obj.network_test_results.test_options.prob_plot_method == nla.gfx.ProbPlotMethod.NEG_LOG_10
                plot_title = sprintf("%s (-log_1_0(P))", plot_title);
            end

            statistic_input = obj.getStatsFromMethodAndName(test_method, plot_statistic);

            p_value_max = fdr_correction.correct(obj.network_atlas, obj.network_test_results.test_options, statistic_input);
            p_value_breakdown_label = fdr_correction.createLable(obj.network_atlas, obj.network_test_results.test_options,...
                statistic_input);

            name_label = sprintf("%s %s\nP < %.2g (%s)", obj.network_test_results.test_display_name, plot_title,...
                p_value_max, p_value_breakdown_label);

            significance_plot = TriMatrix(obj.number_of_networks, "logical", TriMatrixDiag.KEEP_DIAGONAL);
            significance_plot.v = (statistic_input.v < p_value_max) & significance_filter.v;

            % scale values very slightly for display so numbers just below
            % the threshold don't show up white but marked significant
            statistic_input_scaled = TriMatrix(obj.number_of_networks, "double", TriMatrixDiag.KEEP_DIAGONAL);
            statistic_input_scaled.v = statistic_input.v .* (obj.default_discrete_colors / (obj.default_discrete_colors + 1));

            % default values for plotting
            statistic_plot_matrix = statistic_input_scaled;
            p_value_plot_max = p_value_max;
            % determine colormap and operate on values if it's -log10
            switch obj.network_test_results.test_options.prob_plot_method
                case nla.gfx.ProbPlotMethod.LOG
                    color_map = obj.getLogColormap(statistic_input);
                % Here we take a -log10 and change the maximum value to show on the plot
                case nla.gfx.ProbPlotMethod.NEG_LOG_10
                    color_map = parula(obj.default_discrete_colors);

                    statistic_matrix = nla.TriMatrix(obj.number_of_networks, "double", nla.TriMatrixDiag.KEEP_DIAGONAL);
                    statistic_matrix.v = -log10(statistic_input.v);
                    statistic_plot_matrix = statistic_matrix;
                    if test_method == nla.Method.FULL_CONN || test_method == nla.Method.WITHIN_NET_PAIR
                        p_value_plot_max = 2;
                    else
                        p_value_plot_max = 40;
                    end
                otherwise
                    color_map = obj.getColormap(p_value_max);
            end

            % callback function for brain image
            function brainFigureButtonCallback(network1, network2)
                wait_text = sprintf("Generating %s - %s network-pair brain plot", obj.network_atlas.nets(network1).name,...
                    obj.network_atlas.nets(network2).name);
                wait_popup = waitbar(0.05, wait_text);
                nla.gfx.drawBrainVis(edge_test_options, obj.network_test_results.test_options, obj.network_atlas,...
                    nla.gfx.MeshType.STD, 0.25, 3, true, edge_test_result, network1, network2,...
                    any(strcmp(obj.significance_test_names, obj.test_name)));
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

        function value = get.significance_test_names(obj)
            value = obj.network_test_results.significance_test_names;
        end

        function value = get.number_of_networks(obj)
            value = obj.network_atlas.numNets();
        end
    end

    methods (Static)
        function result = plotProbabilityHistogramParameters(probability_histogram, probability_max)
            empirical_fdr = zeros(nla.HistBin.SIZE);
            % TODO: need to figure out what to do about perm_prob_hist

            [~, minimum_index] = min(abs(probability_max, empirical_fdr));
            p_value_max = nla.HistBin.EDGES(minimum_index);
            if (empirical_fdr(minimum_index) > probability_max) && minimum_index > 1
                p_value_max = nla.HistBin.EDGES(minimum_index - 1);
            end

            result = struct();
            result.empirical_fdr = empirical_fdr;
            result.p_value_max = p_value_max;
        end
    end

    methods (Access = protected)
        function color_map = getLogColormap(probabilities_input, p_value_max)
            log_minimum = log10(min(nonzeros(probabilities_input.v)));
            log_minimum = min([-40, log_minimum]);

            % Relevant for BenjaminYekutieli/BenjaminHochberg fdr correction
            default_color_map = [1 1 1];
            if p_value_max ~= 0
                color_map_base = parula(obj.default_discrete_colors);
                color_map = flip(color_map_base(ceil(logspace(log_minimum, 0, obj.default_discrete_colors) .*...
                    obj.default_discrete_colors). :));
                color_map = [color_map; default_color_map];
            else
                color_map = default_color_map;
            end
        end

        function color_map = getColormap(p_value_max)
            default_color_map = [1 1 1];
            if p_value_max == 0
                color_map = default_color_map;
            else
                color_map = flip(parula(obj.default_discrete_colors));
                color_map = [color_map; default_color_map];
            end
        end

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
end