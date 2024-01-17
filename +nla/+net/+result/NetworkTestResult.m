classdef NetworkTestResult < matlab.mixin.Copyable
    %NETWORKTESTRESULT Network Test Results
    % This is the super class that all network test results will be in
    % When a result is created the three repositories (within_network_pair, full_connectome, no_permutations) are set
    % to false. This makes it easier to do an if/else check on them. 
    % The three private methods create the structures and trimatrices to keep the data.
    % Notation:
    %   Test Methods: The method used for ranking the statistics (within net pair, full connectome, no permutation)
    %   Statistics: The statistical results from a specific network test (chi-squared, t-tests)
    %
    % Output object:
    %   test_name: The name of the network test run (chi_squared, hypergeometric, etc)
    %   test_options: The options passed in. Method, plotting methods (formerly input_struct)
    %   within_network_pair: Results from within_network_pair tests
    %   full_connectome: Results from full_connectome tests
    %   no_permutations: Results from the no permutation test
    %   permutation_results: Results from all the permutations of the network tests. These are used in the ranking to create
    %       the results for the test methods
    %
    % Within each of the three results structures will be properties containing the tri-matrices. Each test is different,
    % but all contain:
    %   p_value: TriMatrix with p-values
    %   single_sample_p_value: TriMatrix with the single sample p-value (if available)
    %
    properties
        test_name = "" % Name of the network test run
        test_display_name = "" % Name of the network test for the front-end to display
        test_options = struct() % Options selected for the test. Formerly input_struct
        ranking_statistic = "" 
        within_network_pair = false % Results for within-network-pair tests
        full_connectome = false % Results for full connectome tests (formerly 'experiment wide')
        no_permutations = false % Results for the network tests with no permutations (the 'observed' results)
        permutation_results = struct() % Results for each permutation test used to calculate p-values for the test methods   
    end

    properties (Access = private)
        last_index = 1
    end

    properties (Dependent)
        permutation_count
        is_noncorrelation_input
    end

    properties (Constant)
        test_methods = ["no_permutations", "full_connectome", "within_network_pair"]
        noncorrelation_input_tests = ["chi_squared", "hypergeometric"] % These are tests that do not use correlation coefficients as inputs
    end

    methods
        function obj = NetworkTestResult(test_options, number_of_networks, test_name, test_display_name,...
            test_specific_statistics, ranking_statistic)
            %CONSTRUCTOR Used for creating results.
            %
            % Arguments:
            %   test_options [Struct]: Options for the test. Formerly 'input_struct'
            %   number_of_networks [Int]: The number of networks in the data being analyzed
            %   test_name [String]: The name of the network test being run
            %   test_specific_statistics [Array[String]]: Test statistics for a test. (Example: t_statistic for a t-Test)
            %   ranking_statistic [String]: Test statistic that will be used in ranking

            import nla.TriMatrix nla.TriMatrixDiag

            if nargin == 6
                obj.test_name = test_name;
                obj.test_display_name = test_display_name;
                obj.test_options = test_options;
                obj.ranking_statistic = ranking_statistic;

                obj.createResultsStorage(test_options, number_of_networks, test_specific_statistics)
            elseif nargin > 0
                error("NetworkTestResults requires 5 arguments: Test Options, Number of Networks, Test Name, Test Statistics, and Ranking Statistic")
            end
        end

        function output(obj, edge_test_options, updated_test_options, network_atlas, edge_test_result, flags)
            import nla.TriMatrix nla.TriMatrixDiag nla.net.result.NetworkResultPlotParameter

            % This is the object that will do the calculations for the plots
            result_plot_parameters = NetworkResultPlotParameter(obj, network_atlas, updated_test_options);

            % Cohen's D results for markers
            cohens_d_filter = TriMatrix(network_atlas.numNets, 'logical', TriMatrixDiag.KEEP_DIAGONAL);
            if ~obj.is_noncorrelation_input
                cohens_d_filter.v = (obj.full_connectome.d.v >= updated_test_options.d_max);
            end

            %%
            % Nonpermuted Plotting
            if isfield(flags, "show_nonpermuted") && flags.show_nonpermuted
                obj.noPermutationsPlotting(result_plot_parameters, edge_test_options, edge_test_result,...
                    updated_test_options, flags);
            end
            %%

            %%
            % Full Connectome Plotting
            if isfield(flags, "show_full_conn") && flags.show_full_conn
                obj.fullConnectomePlotting(network_atlas, edge_test_options, edge_test_result, updated_test_options,...
                    cohens_d_filter, flags);       
            end
            %%

            %%
            % Within network pair plotting
            if isfield(flags, "show_within_net_pair") && flags.show_within_net_pair
                obj.withinNetworkPairPlotting(network_atlas, edge_test_options, edge_test_result, updated_test_options,...
                    cohens_d_filter, flags);
            end
            %%
        end

        function merge(obj, other_objects)
            %MERGE Merge two groups of results together. Not guaranteed to be ordered
            if ~iscell(other_objects)
                other_objects = {other_objects};
            end
            for object_index = 1:numel(other_objects)
                % These are the names of the statistics in permutation_results. We only really need to merge the permutation results,
                % all the other results will be 2D while the permutation results are 3D
                statistics = fieldnames(other_objects{object_index}.permutation_results);
                for statistic_index = 1:numel(statistics)
                    statistic = statistics(statistic_index);
                    obj.permutation_results.(statistic{1}).v = [obj.permutation_results.(statistic{1}).v,...
                        other_objects{object_index}.permutation_results.(statistic{1}).v];
                end
            end
        end

        function concatenateResult(obj, other_object)
            %CONCATENATERESULT Add a result to the back of a TriMatrix. Used to keep permutation data.

            statistics = fieldnames(obj.permutation_results);
            for statistic_index = 1:numel(statistics)
                statistic_name = statistics(statistic_index);
                statistic_name = statistic_name{1};
                if ~isempty(obj.permutation_results.(statistic_name)) || ~isequal(obj.permutation_results.(statistic_name), false)
                    obj.permutation_results.(statistic_name).v(:, obj.last_index + 1) = other_object.permutation_results.(statistic_name).v;
                end
            end

            obj.last_index = obj.last_index + 1;
        end

        % I'm assuming this is Get Significance Matrix. It's used for the convergence plots button, but the naming makes zero sense
        % Any help on renaming would be great.
        function [test_number, significance_count_matrix, names] = getSigMat(obj, network_test_options, network_atlas, flags)
            
            import nla.TriMatrix nla.TriMatrixDiag

            test_number = 0;
            significance_count_matrix = TriMatrix(network_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
            names = [];

            if isfield(flags, "show_nonpermuted") && flags.show_nonpermuted
                title = "Non-Permuted";
                p_values = obj.no_permutations.p_value;
                fdr_method = network_test_options.fdr_correction; 
            end
            if isfield(flags, "show_full_conn") && flags.show_full_conn
                title = "Full Connectome";
                p_values = obj.full_connectome.p_value;
                fdr_method = nla.net.mcc.None;
            end
            if isfield(flags, "show_within_net_pair") && flags.show_within_net_pair
                title = "Within Network Pair";
                p_values = obj.within_network_pair.single_sample_p_value;
                fdr_method = network_test_options.fdr_correction;
            end
            [significance, name] = obj.singleSigMat(network_atlas, network_test_options, p_values, fdr_method, title);
            [test_number, significance_count_matrix, names] = obj.appendSignificanceMatrix(test_number, significance_count_matrix,...
                names, significance, name);
        end

        %% This is taken directly from old version to maintain functionality. Not sure anyone uses it.
        function table_new = generateSummaryTable(obj, table_old)
            table_new = [table_old, table(obj.full_connectome.p_value.v, 'VariableNames', [obj.test_name + "P-value"])];
        end

        %%
        % getters for dependent properties
        function value = get.permutation_count(obj)
            % Convenience method to carry permutation from data through here
            if isfield(obj.permutation_results, "p_value_permutations") &&...
                ~isequal(obj.permutation_results.p_value_permutations, false)
                value = size(obj.permutation_results.p_value_permutations.v, 2);
            elseif isfield(obj.permutation_results, "single_sample_p_value_permutations") &&...
                ~isequal(obj.permutation_results.single_sample_p_value_permutations, false)
                value = size(obj.permutation_results.single_sample_p_value_permutations.v, 2);
            else
                error("No permutation test results found.")
            end
        end

        function value = get.is_noncorrelation_input(obj)
            % Convenience method to determine if inputs were correlation coefficients, or "significance" values
            value = any(strcmp(obj.noncorrelation_input_tests, obj.test_name));
        end
        %%
    end

    methods (Access = private)
        function createResultsStorage(obj, test_options, number_of_networks, test_specific_statistics)
            %CREATERESULTSSTORAGE Create the substructures for the methods chosen

            % create the results containers. This replaces the false boolean with a struct of TriMatrices
            for test_method_index = 1:numel(obj.test_methods)
                if isequal(obj.(obj.test_methods(test_method_index)), false) &&...
                    isequal(test_options.(obj.test_methods(test_method_index)), true)
                    obj.(obj.test_methods(test_method_index)) = struct();
                    obj.createPValueTriMatrices(number_of_networks, obj.test_methods(test_method_index));
                end
            end
            % This creates all the permutations and test specific stats (chi2, t, w, etc)
            obj.createTestSpecificResultsStorage(number_of_networks, test_specific_statistics);
        end

        function createTestSpecificResultsStorage(obj, number_of_networks, test_specific_statistics)
            %CREATETESTSPECIFICRESULTSSTORAGE Create the substructures for the specific statistical tests

            import nla.TriMatrix nla.TriMatrixDiag

            obj.permutation_results.p_value_permutations = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            if ~any(strcmp(obj.test_name, obj.noncorrelation_input_tests))
                obj.permutation_results.single_sample_p_value_permutations = TriMatrix(number_of_networks,...
                    TriMatrixDiag.KEEP_DIAGONAL);
            end

            for statistic_index = 1:numel(test_specific_statistics)
                test_statistic = test_specific_statistics(statistic_index);
                obj.no_permutations.(test_statistic) = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                obj.permutation_results.(strcat(test_statistic, "_permutations")) = TriMatrix(number_of_networks,...
                    TriMatrixDiag.KEEP_DIAGONAL);
            end
        end

        function createPValueTriMatrices(obj, number_of_networks, test_method)
            %CREATEPVALUETRIMATRICES Creates the p-value substructure for the test method

            import nla.TriMatrix nla.TriMatrixDiag

            obj.(test_method).p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL); % p-value by statistic rank
            obj.(test_method).statistic_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL); % p-value by statistic rank
            if ~isequal(test_method, "full_connectome") && ~any(strcmp(obj.test_name, obj.noncorrelation_input_tests))
                obj.(test_method).single_sample_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            end
            %Cohen's D results
            obj.(test_method).d = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
        end

        function histogram = createHistogram(obj, statistic)
            if ~endsWith(statistic, "_permutations")
                statistic = strcat(statistic, "_permutations");
            end
            permutation_data = obj.permutation_results.(statistic);
            histogram = zeros(nla.HistBin.SIZE, "uint32");

            for permutation = 1:obj.permutation_count
                histogram = histogram + uint32(histcounts(permutation_data.v(:, permutation), nla.HistBin.EDGES)');
            end
        end

        function noPermutationsPlotting(obj, plot_parameters, edge_test_options, edge_test_result, updated_test_options, flags)
            import nla.gfx.createFigure nla.net.result.plot.PermutationTestPlotter nla.net.result.chord.ChordPlotter
            
            plot_test_type = "no_permutations";

            % Get the plot parameters (titles, stats, labels, max, min, etc)
            plot_title = sprintf('Non-permuted Method\nNon-permuted Significance');
            
            p_value = obj.choosePlottingMethod(updated_test_options, plot_test_type);
            p_value_plot_parameters = plot_parameters.plotProbabilityParameters(edge_test_options, edge_test_result,...
                plot_test_type, p_value, plot_title, updated_test_options.fdr_correction, false);

            % No permutations results
            if flags.plot_type == nla.PlotType.FIGURE
                plot_figure = createFigure(500, 900);

                p_value_vs_network_size_parameters = plot_parameters.plotProbabilityVsNetworkSize("no_permutations",...
                    p_value);
                plotter = PermutationTestPlotter(plot_parameters.network_atlas);
                % don't need to create a reference to axis since drawMatrixOrg takes a figure as a reference
                % plot the probability

                % Hard-coding sucks, but to make this adaptable for every type of test and method, here we are
                x_coordinate = 0;
                y_coordinate = 425;
                plotter.plotProbability(plot_figure, p_value_plot_parameters, x_coordinate, y_coordinate);

                % do need to create a reference here for the axes since this just uses matlab builtins
                axes = subplot(2,1,2);
                plotter.plotProbabilityVsNetworkSize(p_value_vs_network_size_parameters, axes,...
                    "Non-permuted P-values vs. Network-Pair Size");

            elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                if isfield(updated_test_options, 'edge_chord_plot_method')
                    p_value_plot_parameters.edge_chord_plot_method = updated_test_options.edge_chord_plot_method;
                end
                chord_plotter = ChordPlotter(plot_parameters.network_atlas, edge_test_result);
                chord_plotter.generateChordFigure(p_value_plot_parameters, flags.plot_type);
            end
        end

        function fullConnectomePlotting(obj, network_atlas, edge_test_options, edge_test_result, updated_test_options, cohens_d_filter, flags)
            import nla.gfx.createFigure nla.net.result.NetworkResultPlotParameter nla.net.result.plot.PermutationTestPlotter
            import nla.net.result.chord.ChordPlotter
            
            plot_test_type = "full_connectome";

            plot_title = sprintf("Full Connectome Method\nNetwork vs. Connectome Significance");
            plot_title_threshold = sprintf('%s (D > %g)', plot_title, updated_test_options.d_max);
            
            p_value = obj.choosePlottingMethod(updated_test_options, plot_test_type);
            
            % This is the object that will do the calculations for the plots
            result_plot_parameters = NetworkResultPlotParameter(obj, edge_test_options.net_atlas, updated_test_options);

            % Get the plot parameters (titles, stats, labels, etc.)
            full_connectome_p_value_plot_parameters = result_plot_parameters.plotProbabilityParameters(...
                edge_test_options, edge_test_result, plot_test_type, p_value, plot_title,...
                nla.net.mcc.None(), false);

            % Mark the probability trimatrix with cohen's d results
            full_connectome_p_value_plot_parameters_with_cohensd = result_plot_parameters.plotProbabilityParameters(...
                edge_test_options, edge_test_result, plot_test_type, p_value, plot_title_threshold, ...
                nla.net.mcc.None(), cohens_d_filter);

            if flags.plot_type == nla.PlotType.FIGURE
                
               
                p_value_vs_network_size_parameters = result_plot_parameters.plotProbabilityVsNetworkSize("no_permutations",...
                    p_value);
                full_connectome_p_value_vs_network_size_parameters = result_plot_parameters.plotProbabilityVsNetworkSize(...
                    plot_test_type, p_value);

                % create a histogram
                p_value_histogram = obj.createHistogram(p_value);

                plotter = PermutationTestPlotter(edge_test_options.net_atlas);
                
                % With the way subplot works, we have to do the plotting this way. I tried assigning variables to the subplots,
                % but then the plots get put under different layers. 
                if obj.is_noncorrelation_input
                    plot_figure = createFigure(1000, 900);
                    plotter.plotProbabilityHistogram(subplot(2,2,2), p_value_histogram,  obj.full_connectome.p_value.v,...
                        obj.no_permutations.p_value.v, obj.test_display_name, updated_test_options.prob_max);
                    plotter.plotProbabilityVsNetworkSize(p_value_vs_network_size_parameters, subplot(2,2,3),...
                        "Non-permuted P-values vs. Network-Pair Size");
                    plotter.plotProbabilityVsNetworkSize(full_connectome_p_value_vs_network_size_parameters, subplot(2,2,4),...
                        "Permuted P-values vs. Net-Pair Size");
                    x_coordinate = 25;
                else
                    plot_figure = createFigure(1200, 900);
                    plotter.plotProbabilityVsNetworkSize(p_value_vs_network_size_parameters, subplot(2,3,5),...
                        "Non-permuted P-values vs. Network-Pair Size");
                    plotter.plotProbabilityVsNetworkSize(full_connectome_p_value_vs_network_size_parameters, subplot(2,3,6),...
                        "Permuted P-values vs. Net-Pair Size");
                    plotter.plotProbabilityHistogram(subplot(2,3,4), p_value_histogram,  obj.full_connectome.p_value.v,...
                        obj.no_permutations.p_value.v, obj.test_display_name, updated_test_options.prob_max);
                    x_coordinate = 75;
                end

                y_coordinate = 425;
                [w, ~] = plotter.plotProbability(plot_figure, full_connectome_p_value_plot_parameters, x_coordinate, y_coordinate);
                if ~obj.is_noncorrelation_input
                    plotter.plotProbability(plot_figure, full_connectome_p_value_plot_parameters_with_cohensd, w + 50, y_coordinate);
                end

            elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                if isfield(updated_test_options, 'edge_chord_plot_method')
                    full_connectome_p_value_plot_parameters.edge_chord_plot_method = updated_test_options.edge_chord_plot_method;
                    full_connectome_p_value_plot_parameters_with_cohensd.edge_chord_plot_method = updated_test_options.edge_chord_plot_method;
                end

                chord_plotter = ChordPlotter(network_atlas, edge_test_result);
                if obj.is_noncorrelation_input && isfield(updated_test_options, 'd_thresh_chord_plot') && updated_test_options.d_thresh_chord_plot
                    chord_plotter.generateChordFigure(full_connectome_p_value_plot_parameters_with_cohensd, flags.plot_type);
                else
                    chord_plotter.generateChordFigure(full_connectome_p_value_plot_parameters, flags.plot_type)
                end
            end
        end

        function withinNetworkPairPlotting(obj, network_atlas, edge_test_options, edge_test_result, updated_test_options, cohens_d_filter, flags)
            import nla.gfx.createFigure nla.net.result.NetworkResultPlotParameter nla.net.result.plot.PermutationTestPlotter
            import nla.net.result.chord.ChordPlotter

            plot_test_type = "within_network_pair";

            plot_title = sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair');

            result_plot_parameters = NetworkResultPlotParameter(obj, edge_test_options.net_atlas, updated_test_options);

            p_value = obj.choosePlottingMethod(updated_test_options, plot_test_type);

            within_network_pair_p_value_vs_network_parameters = result_plot_parameters.plotProbabilityVsNetworkSize(...
                plot_test_type, p_value);

            within_network_pair_p_value_parameters = result_plot_parameters.plotProbabilityParameters(edge_test_options,...
                edge_test_result, plot_test_type, p_value, plot_title, updated_test_options.fdr_correction, false);

            plot_title = sprintf("Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair (D > %g)",...
                updated_test_options.d_max);
            within_network_pair_p_value_parameters_with_cohensd = result_plot_parameters.plotProbabilityParameters(...
                edge_test_options, edge_test_result, plot_test_type, p_value, plot_title,...
                updated_test_options.fdr_correction, cohens_d_filter);

            if flags.plot_type == nla.PlotType.FIGURE

                plotter = PermutationTestPlotter(edge_test_options.net_atlas);
                y_coordinate = 425;
                if obj.is_noncorrelation_input
                    plot_figure = createFigure(500, 900);
                    x_coordinate = 0;
                    plotter.plotProbabilityVsNetworkSize(within_network_pair_p_value_vs_network_parameters, subplot(2,1,2),...
                        "Within Net-Pair P-values vs. Net-Pair Size");
                    plotter.plotProbability(plot_figure, within_network_pair_p_value_parameters, x_coordinate, y_coordinate);
                else
                    plot_figure = createFigure(1000,900);
                    x_coordinate = 25;
                    plotter.plotProbabilityVsNetworkSize(within_network_pair_p_value_vs_network_parameters, subplot(2,2,3),...
                        "Within Net-Pair P-values vs. Net-Pair Size");
                    [w, ~] = plotter.plotProbability(plot_figure, within_network_pair_p_value_parameters, x_coordinate, y_coordinate);
                    plotter.plotProbability(plot_figure, within_network_pair_p_value_parameters_with_cohensd, w - 50, y_coordinate);
                end

            elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                if isfield(updated_test_options, 'edge_chord_plot_method')
                    within_network_pair_p_value_parameters.edge_chord_plot_method = updated_test_options.edge_chord_plot_method;
                    within_network_pair_p_value_parameters_with_cohensd.edge_chord_plot_method = updated_test_options.edge_chord_plot_method;
                end

                chord_plotter = ChordPlotter(network_atlas, edge_test_result);
                if obj.is_noncorrelation_input && isfield(updated_test_options, 'd_thresh_chord_plot') && updated_test_options.d_thresh_chord_plot
                    chord_plotter.generateChordFigure(within_network_pair_p_value_parameters_with_cohensd, flags.plot_type);
                else
                    chord_plotter.generateChordFigure(within_network_pair_p_value_parameters, flags.plot_type);
                end
            end
        end

        function p_value = choosePlottingMethod(obj, test_options, plot_test_type)
            p_value = "p_value";
            if test_options == nla.gfx.ProbPlotMethod.STATISTIC
                p_value = strcat("statistic_", p_value);
            end
            if ~obj.is_noncorrelation_input && plot_test_type == "within_network_pair"
                p_value = strcat("single_sample_", p_value);
            end
        end
        
        % I don't really know what these do and haven't really thought about it. Hence the bad naming.
        function [sig, name] = singleSigMat(obj, network_atlas, edge_test_options, p_value, mcc_method, title_prefix)
            p_value_max = mcc_method.correct(network_atlas, edge_test_options, p_value);
            p_breakdown_labels = mcc_method.createLabel(network_atlas, edge_test_options, p_value);

            sig = nla.TriMatrix(network_atlas.numNets(), 'double', nla.TriMatrixDiag.KEEP_DIAGONAL);
            sig.v = (p_value.v < p_value_max);
            name = sprintf("%s %s P < %.2g (%s)", title_prefix, obj.test_display_name, p_value_max, p_breakdown_labels);
        end

        function [number_of_tests, sig_count_mat, names] = appendSignificanceMatrix(...
            obj, number_of_tests, sig_count_mat, names, sig, name...
        )
            number_of_tests = number_of_tests + 1;
            sig_count_mat.v = sig_count_mat.v + sig.v;
            names = [names name];
        end
    end

    methods (Static)
        function options = editableOptions()
            % options that can be edited post-run (ie: are simple
            % thresholds etc. for summary statistics, or generally can be
            % modified without requiring re-permutation)
            import nla.inputField.Integer nla.inputField.Number 
            options = {Integer('behavior_count', 'Test count:', 1, 1, Inf),...
                Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1)};
        end
    end
end