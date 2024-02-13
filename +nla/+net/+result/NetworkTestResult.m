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
        significance_test
    end

    properties (Constant)
        test_methods = ["no_permutations", "within_network_pair", "full_connectome"]
        significance_test_names = ["chi_squared", "hypergeometric"] % These are tests that do not use correlation coefficients as inputs
    end

    methods
        function obj = NetworkTestResult(test_options, number_of_networks, test_name, test_display_name,...
            test_specific_statistics)
            %CONSTRUCTOR Used for creating results.
            %
            % Arguments:
            %   test_options [Struct]: Options for the test. Formerly 'input_struct'
            %   number_of_networks [Int]: The number of networks in the data being analyzed
            %   test_name [String]: The name of the network test being run
            %   test_specific_statistics [Array[String]]: Test statistics for a test. (Example: t_statistic for a t-Test)

            import nla.TriMatrix nla.TriMatrixDiag

            if nargin == 5
                obj.test_name = test_name;
                obj.test_display_name = test_display_name;
                obj.test_options = test_options;

                obj.createResultsStorage(test_options, number_of_networks, test_specific_statistics)
            elseif nargin > 0
                error("NetworkTestResults requires 4 arguments: Test Options, Number of Networks, Test Name, Test Statistics")
            end
        end

        function output(obj, edge_test_options, updated_test_options, network_atlas, edge_test_result, flags)
            import nla.net.result.NetworkResultPlotParameter 
            import nla.gfx.createFigure nla.net.result.plot.FullConnectomePlotter 
            import nla.net.result.plot.WithinNetworkPairPlotter
            import nla.TriMatrix nla.TriMatrixDiag

            % This is the object that will do the calculations for the plots
            result_plot_parameters = NetworkResultPlotParameter(obj, network_atlas, updated_test_options);

            % We need the no-permutations vs. network size no matter what, so we're just doing it here.
            p_value_vs_network_size_parameters = result_plot_parameters.plotProbabilityVsNetworkSize("no_permutations",...
                "p_value");

            % Cohen's D results for markers
            cohens_d_filter = TriMatrix(network_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
            cohens_d_filter.v = (obj.full_connectome.d.v >= updated_test_options.d_max);

            significance_input = any(strcmp(obj.test_name, obj.significance_test_names));
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
                obj.fullConnectomePlotting(edge_test_options, edge_test_result, updated_test_options, cohens_d_filter, flags);       
            end
            %%

            %%
            % Within network pair plotting
            if isfield(flags, "show_within_net_pair") && flags.show_within_net_pair
                obj.withinNetworkPairPlotting(edge_test_options, edge_test_result, updated_test_options, cohens_d_filter, flags);
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

        function value = get.permutation_count(obj)
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

        function value = get.significance_test(obj)
            value = any(strcmp(obj.significance_test_names, obj.test_name));
        end
    end

    methods (Access = private)
        function createResultsStorage(obj, test_options, number_of_networks, test_specific_statistics)
            %CREATERESULTSSTORAGE Create the substructures for the methods chosen
            %   

            % Our 3 test methods. No permutations, Within-Network-Piar, Full Connectome
            % Creating an array of pairs status (yes/no) and name for the results (Find a better way, code-monkey)
            test_methods_and_names = struct("no_permutations", test_options.nonpermuted,...
                "within_network_pair", test_options.within_net_pair,...
                "full_connectome", test_options.full_conn);
            
            % Calling function to create results containers
            for test_method_index = 1:numel(obj.test_methods)
                if test_methods_and_names.(obj.test_methods(test_method_index))
                    obj.createPValueTriMatrices(number_of_networks, (obj.test_methods(test_method_index)));
                    obj.createTestSpecificResultsStorage(number_of_networks, test_specific_statistics);
                end
            end
        end

        function createTestSpecificResultsStorage(obj, number_of_networks, test_specific_statistics)
            %CREATETESTSPECIFICRESULTSSTORAGE Create the substructures for the specific statistical tests

            import nla.TriMatrix nla.TriMatrixDiag

            obj.permutation_results.p_value_permutations = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            obj.permutation_results.single_sample_p_value_permutations = TriMatrix(number_of_networks,...
                TriMatrixDiag.KEEP_DIAGONAL);

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

            % I could've looped this, too. Just copy/paste from earlier, so it stays. Plus, this is in every test 
            % regardless of test or method
            obj.(test_method) = struct();
            obj.(test_method).p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            obj.(test_method).single_sample_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            %Cohen's D results
            obj.(test_method).d = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
        end

        function histogram = createHistogram(obj, test_method, statistic)
            if ~endsWith(statistic, "_permutations")
                statistic = strcat(statistic, "_permutations");
            end
            permutation_data = obj.permutation_results.(statistic);
            histogram = zeros(nla.HistBin.SIZE, "uint32");

            for permutation = 1:obj.permutation_count
                histogram = histogram + uint32(histcounts(permutation_data.v(:, permutation), nla.HistBin.EDGES)');
            end
        end

        function noPermutationsPlotting(obj, plot_parameters, edge_test_options, edge_test_result, updated_test_options,...
                flags)
            import nla.net.result.plot.NoPermutationPlotter nla.gfx.createFigure

            % No permutations results
            if flags.plot_type == nla.PlotType.FIGURE
                plot_figure = createFigure(500, 900);

                % Get the plot parameters (titles, stats, labels, max, min, etc)
                plot_title = sprintf('Non-permuted Method\nNon-permuted Significance');
                p_value = "p_value";
                if ~any(strcmp(obj.test_name, obj.significance_test))
                    p_value = "single_sample_p_value";
                end
                p_value_plot_parameters = plot_parameters.plotProbabilityParameters(edge_test_options, edge_test_result,...
                    "no_permutations", p_value, plot_title, updated_test_options.fdr_correction, false);
                p_value_vs_network_size_parameters = plot_parameters.plotProbabilityVsNetworkSize("no_permutations",...
                    p_value);
                plotter = NoPermutationPlotter(plot_parameters.network_atlas);
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
            end
        end

        function fullConnectomePlotting(obj, edge_test_options, edge_test_result, updated_test_options, cohens_d_filter, flags)
            import nla.gfx.createFigure nla.net.result.NetworkResultPlotParameter nla.net.result.plot.FullConnectomePlotter

            plot_title = sprintf("Full Connectome Method\nNetwork vs. Connectome Significance");
            plot_title_threshold = sprintf('%s (D > %g)', plot_title, updated_test_options.d_max);
            if flags.plot_type == nla.PlotType.FIGURE

                % This is the object that will do the calculations for the plots
                result_plot_parameters = NetworkResultPlotParameter(obj, edge_test_options.net_atlas, updated_test_options);

                % Get the plot parameters (titles, stats, labels, etc.)
                %TODO: why do we use no fdr here?
                full_connectome_p_value_plot_parameters = result_plot_parameters.plotProbabilityParameters(...
                    edge_test_options, edge_test_result, "full_connectome", "p_value", plot_title,...
                    nla.net.mcc.None(), false);

                % Mark the probability trimatrix with cohen's d results
                full_connectome_p_value_plot_parameters_with_cohensd = result_plot_parameters.plotProbabilityParameters(...
                    edge_test_options, edge_test_result, "full_connectome", "p_value", plot_title_threshold, ...
                    nla.net.mcc.None(), cohens_d_filter);
                
                p_value = "p_value";
                if ~obj.significance_test
                    p_value = "single_sample_p_value";
                end
                p_value_vs_network_size_parameters = result_plot_parameters.plotProbabilityVsNetworkSize("no_permutations",...
                    p_value);
                full_connectome_p_value_vs_network_size_parameters = result_plot_parameters.plotProbabilityVsNetworkSize(...
                    "full_connectome", "p_value");

                % create a histogram
                p_value_histogram = obj.createHistogram("full_connectome", "p_value");

                plotter = FullConnectomePlotter(edge_test_options.net_atlas);
                
                % With the way subplot works, we have to do the plotting this way. I tried assigning variables to the subplots,
                % but then the plots get put under different layers. 
                if obj.significance_test
                    plot_figure = createFigure(1000, 900);
                    plotter.plotProbabilityHistogram(subplot(2,2,2), p_value_histogram,  obj.full_connectome.p_value.v,...
                        obj.permutation_results.p_value_permutations.v(:,1), obj.test_display_name, updated_test_options.prob_max);
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
                        obj.permutation_results.p_value_permutations.v(:,1), obj.test_display_name, updated_test_options.prob_max);
                    x_coordinate = 75;
                end

                y_coordinate = 425;
                [w, ~] = plotter.plotProbability(plot_figure, full_connectome_p_value_plot_parameters, x_coordinate, y_coordinate);
                if ~obj.significance_test
                    plotter.plotProbability(plot_figure, full_connectome_p_value_plot_parameters_with_cohensd, w + 50, y_coordinate);
                end
            end
        end

        function withinNetworkPairPlotting(obj, edge_test_options, edge_test_result, updated_test_options, cohens_d_filter, flags)
            import nla.gfx.createFigure nla.net.result.NetworkResultPlotParameter nla.net.result.plot.WithinNetworkPairPlotter

            plot_title = sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair');

            if flags.plot_type == nla.PlotType.FIGURE

                result_plot_parameters = NetworkResultPlotParameter(obj, edge_test_options.net_atlas, updated_test_options);

                within_network_pair_p_value_vs_network_parameters = result_plot_parameters.plotProbabilityVsNetworkSize(...
                    "within_network_pair", "p_value");

                within_network_pair_p_value_parameters = result_plot_parameters.plotProbabilityParameters(edge_test_options,...
                    edge_test_result, "within_network_pair", "p_value", plot_title, updated_test_options.fdr_correction, false);

                plot_title = sprintf("Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair (D > %g)",...
                    updated_test_options.d_max);
                within_network_pair_p_value_parameters_with_cohensd = result_plot_parameters.plotProbabilityParameters(...
                    edge_test_options, edge_test_result, "within_network_pair", "p_value", plot_title,...
                    updated_test_options.fdr_correction, cohens_d_filter);

                plotter = WithinNetworkPairPlotter(edge_test_options.net_atlas);
                y_coordinate = 425;
                if obj.significance_test
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
            end
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