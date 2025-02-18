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
        % TODO: replace wtih enums
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
            import nla.NetworkLevelMethod

            if isfield(flags, "show_nonpermuted") && flags.show_nonpermuted
                test_method = "no_permutations";
            elseif isfield(flags, "show_full_conn") && flags.show_full_conn
                test_method = "full_connectome";
            elseif isfield(flags, "show_within_net_pair") && flags.show_within_net_pair
                test_method = "within_network_pair";
            end

            network_result_plot = nla.net.result.plot.NetworkTestPlot(obj, edge_test_result, network_atlas,...
                test_method, edge_test_options, updated_test_options);
            network_result_plot.drawFigure(nla.PlotType.FIGURE)
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

        function runDiagnosticPlots(obj, edge_test_options, updated_test_options, edge_test_result, network_atlas, flags)
            import nla.NetworkLevelMethod

            diagnostics_plot = nla.gfx.plots.DiagnosticPlot(edge_test_options, updated_test_options,...
                edge_test_result, network_atlas, obj);

            if isfield(flags, "show_nonpermuted") && flags.show_nonpermuted
                test_method = "no_permutations";
            elseif isfield(flags, "show_full_conn") && flags.show_full_conn
                test_method = "full_connectome";
            elseif isfield(flags, "show_within_net_pair") && flags.show_within_net_pair
                test_method = "within_network_pair";
            end

            diagnostics_plot.displayPlots(test_method);
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
                p_values = obj.no_permutations.uncorrected_two_sample_p_value;
                fdr_method = network_test_options.fdr_correction; 
            end
            if isfield(flags, "show_full_conn") && flags.show_full_conn
                title = "Full Connectome";
                p_values = obj.full_connectome.uncorrected_two_sample_p_value;
                fdr_method = network_test_options.fdr_correction;
            end
            if isfield(flags, "show_within_net_pair") && flags.show_within_net_pair
                title = "Within Network Pair";
                p_values = obj.within_network_pair.uncorrected_single_sample_p_value;
                fdr_method = network_test_options.fdr_correction;
            end
            [significance, name] = obj.singleSigMat(network_atlas, network_test_options, p_values, fdr_method, title);
            [test_number, significance_count_matrix, names] = obj.appendSignificanceMatrix(test_number, significance_count_matrix,...
                names, significance, name);
        end

        %% This is taken directly from old version to maintain functionality. Not sure anyone uses it.
        function table_new = generateSummaryTable(obj, table_old)
            table_new = [table_old, table(...
                obj.full_connectome.uncorrected_two_sample_p_value.v, 'VariableNames', [obj.test_display_name + "Full Connectome Two Sample p-value"]...
            )];
        end

        %%
        % getters for dependent properties
        function value = get.permutation_count(obj)
            % Convenience method to carry permutation from data through here
            if isfield(obj.permutation_results, "two_sample_p_value_permutations") &&...
                ~isequal(obj.permutation_results.two_sample_p_value_permutations, false)
                value = size(obj.permutation_results.two_sample_p_value_permutations.v, 2);
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

            non_correlation_test = any(strcmp(obj.test_name, obj.noncorrelation_input_tests));
            uncorrected_names = ["uncorrected_", "legacy_"];
            corrected_names = ["winkler_", "westfall_young_"];

            switch test_method
                case "no_permutations"
                    for uncorrected_name = uncorrected_names
                        p_value = "two_sample_p_value";
                        obj.(test_method).(strcat(uncorrected_name, p_value)) = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                        if isequal(non_correlation_test, false)                
                            p_value = "single_sample_p_value";
                            obj.(test_method).(strcat(uncorrected_name, p_value)) = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                        end
                    end
                case "full_connectome"
                    p_value = "two_sample_p_value";
                    for name = [corrected_names uncorrected_names]
                        obj.(test_method).(strcat(name, p_value)) = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                    end
                case "within_network_pair"
                    % This is so hacky, but Matlab doesn't play well with logical order-of-operations
                    if isequal(non_correlation_test, true)
                        p_value = "two_sample_p_value";
                    else
                        p_value = "single_sample_p_value";
                    end
                    for name = [corrected_names uncorrected_names]
                        obj.(test_method).(strcat(name, p_value)) = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                    end
            end

            % We need the permutation fields for all results. We need the two-sample ones for everything         
            obj.permutation_results.two_sample_p_value_permutations = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            if isequal(non_correlation_test, false)
                obj.permutation_results.single_sample_p_value_permutations = TriMatrix(number_of_networks,...
                    TriMatrixDiag.KEEP_DIAGONAL);
            end

            %Cohen's D results
            obj.(test_method).d = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        % I don't really know what these do and haven't really thought about it. Hence the bad naming.
        function [sig, name] = singleSigMat(obj, network_atlas, edge_test_options, p_value, mcc_method, title_prefix)
            mcc_method = nla.net.mcc.(mcc_method)();
            p_value_max = mcc_method.correct(network_atlas, edge_test_options, p_value);
            p_breakdown_labels = mcc_method.createLabel(network_atlas, edge_test_options, p_value);

            sig = nla.TriMatrix(network_atlas.numNets(), 'double', nla.TriMatrixDiag.KEEP_DIAGONAL);
            sig.v = (p_value.v < p_value_max);
            name = sprintf("%s %s P < %.2g (%s)", title_prefix, obj.test_display_name, p_value_max, p_breakdown_labels);
            if p_value_max == 0
                name = sprintf("%s %s P = 0 (%s)", title_prefix, obj.test_display_name, p_breakdown_labels);
            end
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
            options = {...
                Integer('behavior_count', 'Test count:', 1, 1, Inf),...
                Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1),...
                Number('d_max', "Cohen's D threshold >", 0, 0.5, 1),...
            };
        end

        function probability = getPValueNames(test_method, test_name)
            import nla.NetworkLevelMethod
            noncorrelation_input_tests = ["chi_squared", "hypergeometric"];
            non_correlation_test = any(strcmp(test_name, noncorrelation_input_tests));

            probability = "two_sample_p_value";
            if isequal(non_correlation_test, false)
                if isequal(test_method, "no_permutations") || isequal(test_method, "within_network_pair")
                    probability = "single_sample_p_value";
                end
            end
        end
    end
end