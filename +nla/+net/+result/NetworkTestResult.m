classdef NetworkTestResult < matlab.mixin.Copyable
    % Network level test results
    % Class to store all relevant results for a network level test. Each test will create an instance of this to store results
    %
    % :param test_options: Options and inputs for tests to be run (also called input_struct)
    % :param number_of_networks: The number of networks in the network atlas
    % :param test_name: The name of the network test run
    % :param test_display_name: The name of the network test for display
    % :param test_specific_statistics: The statistics that a specific test produces
    % :param ranking_statistic: The statistic used for calculating p-values

    properties
        test_name = "" % Name of the network test run
        test_display_name = "" % The name of the network test for display
        test_options = struct() % Options and inputs for tests to be run (also called input_struct)
        ranking_statistic = "" % The statistic used for calculating p-values
        within_network_pair = false % Results of the within network pair test. Single sample p-values (except :math:`\chi^2`\ and hypergeometric tests). "legacy_" results use the individual test p-values to rank and determine the final p-value.
        full_connectome = false % Results of the full_connectome test. Two sample p-values.
        no_permutations = false % Results for the non-permuted test. Single sample p-values (except :math:`\chi^2`\ and hypergeometric tests).
        permutation_results = struct() % Results of each permutation. Statistics and p-values. Note: The p-values are for each individual permutation test, not the overall p-value.  
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
            import nla.TriMatrix nla.TriMatrixDiag
            if nargin == 0
                return
            end

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

        % Used for plotting
        function output(obj, edge_test_options, updated_test_options, network_atlas, edge_test_result, flags)
            % Outputs data to be plotted using nla.net.result.plot.NetworkTestPlot
            %
            % :param edge_test_options: The test_options used to instantiate the class. Contains the functional connectivity and network atlas among other options
            % :param updated_test_options: The network test options. These can also include the options for plotting.
            % :param network_atlas: The network atlas
            % :param edge_test_result: Results of the edge level test.
            % :param flags: More options that are used after the tests have run. One of them is which test method to plot.
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

        % Use for merging multiple results together into one
        function merge(obj, other_objects)
            % Used to merge multiple results together into one
            %
            % :param other_objects: The other result objects to merge into this result object

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
            % Concatenate results together. This is used to preserve the individual permutation results.
            %
            % :param other_object: The object to append to the end of the current result

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

        function table_new = generateSummaryTable(obj, table_old)
            table_new = [table_old, table(...
                obj.full_connectome.uncorrected_two_sample_p_value.v, 'VariableNames', [obj.test_display_name + "Full Connectome Two Sample p-value"]...
            )];
        end

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

        % Convenience method to determine if inputs were correlation coefficients, or "significance" values
        function value = get.is_noncorrelation_input(obj)
            value = any(strcmp(obj.noncorrelation_input_tests, obj.test_name));
        end

        function set.is_noncorrelation_input(obj, ~)
        end

        function set.permutation_count(obj, ~)
        end
        %%
    end

    methods (Access = private)
        function createResultsStorage(obj, test_options, number_of_networks, test_specific_statistics)
            % Creates the objects to hold results. Uses statistic names from test objects.
            %
            % :param test_options: The test options
            % :param number_of_networks: The number of networks. Used to determine the size of the TriMatrix result. A property of the Network Atlas
            % :param test_specific_statistics: The statistics used in each test. A property of each test.

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
            import nla.TriMatrix nla.TriMatrixDiag

            for statistic_index = 1:numel(test_specific_statistics)
                test_statistic = test_specific_statistics(statistic_index);
                obj.no_permutations.(test_statistic) = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                obj.permutation_results.(strcat(test_statistic, "_permutations")) = TriMatrix(number_of_networks,...
                    TriMatrixDiag.KEEP_DIAGONAL);
            end
        end

        function createPValueTriMatrices(obj, number_of_networks, test_method)
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

        function p_value = choosePlottingMethod(obj, test_options, plot_test_type)
            p_value = "p_value";
            if test_options == nla.gfx.ProbPlotMethod.STATISTIC
                p_value = strcat("statistic_", p_value);
            end
            if ~obj.is_noncorrelation_input && plot_test_type == "within_network_pair"
                p_value = strcat("single_sample_", p_value);
            end
        end
    end

    methods (Static)
        function options = editableOptions()
            % Static method to return options that can be adjusted afterwards.
            %
            % :return: Options. Defaults to behavior_count, prob_max (The threshold for p-values), d_max (The threshold for Cohen's D values)

            import nla.inputField.Integer nla.inputField.Number 
            options = {...
                Integer('behavior_count', 'Test count:', 1, 1, Inf),...
                Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1),...
                Number('d_max', "Cohen's D threshold >", 0, 0.5, 1),...
            };
        end

        function probability = getPValueNames(test_method, test_name)
            % Static method to determine prefixes of p-values for test results
            %
            % :param test_method: No permutations, full connectome, or within network pair
            % :param test_name: The name of the test run
            % :return: The full name of the p-value. (example: "single_sammple_p_value")

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

        function converted_data_struct = loadOldVersionData(result_struct)
            import nla.net.result.NetworkTestResult nla.TriMatrix nla.TriMatrixDiag nla.NetworkAtlas

            number_of_results = numel(result_struct.net_results);
            test_options = result_struct.input_struct;
            
            network_test_options = result_struct.net_input_struct;
            network_test_options.ranking_method = "Uncorrected";
            network_test_options.no_permutations = network_test_options.nonpermuted;
            network_test_options.full_connectome = network_test_options.full_conn;
            network_test_options.within_network_pair = network_test_options.within_net_pair;
            network_test_options = rmfield(network_test_options, ["nonpermuted", "full_conn", "within_net_pair"]);

            network_atlas = NetworkAtlas();
            fields = fieldnames(result_struct.net_atlas);
            for field_index = 1:numel(fields)
                network_atlas.(fields{field_index}) = result_struct.net_atlas.(fields{field_index});
            end
            number_of_networks = network_atlas.numNets();
            
            converted_data_struct = struct(...
                'test_options', test_options,...
                'network_atlas', network_atlas,...
                'network_test_options', network_test_options,...
                'edge_test_results', result_struct.edge_result,...
                'version', result_struct.version,...
                'commit', result_struct.commit,...
                'commit_short', result_struct.commit_short...
            );
            
            converted_data_struct.permutation_network_test_results = {};
            d = false;
            single_sample_d = false;

            for result_number = 1:number_of_results
                switch result_struct.perm_net_results{result_number}.name
                    case "Chi-Squared"
                        test_name = "chi_squared";
                        test_display_name = "Chi-Squared";
                        ranking_statistic = "chi2_statistic";
                        is_noncorrelation_input = 1;
                    case "Hypergeometric"
                        test_name = "hypergeometric";
                        test_display_name = "Hypergeometric";
                        ranking_statistic = "two_sample_p_value";
                        is_noncorrelation_input = 1;
                    case "Kolmogorov-Smirnov"
                        test_name = "kolmogorov_smirnov";
                        test_display_name = "Kolmogorov-Smirnov";
                        ranking_statistic = "ks_statistic";
                        is_noncorrelation_input = 0;
                    case "Student's T"
                        test_name = "students_t";
                        test_display_name = "Student's T-test";
                        ranking_statistic = "t_statistic";
                        is_noncorrelation_input = 0;
                    case "Welch's T"
                        test_name = "welchs_t";
                        test_display_name = "Welch's T-test";
                        ranking_statistic = "t_statistic";
                        is_noncorrelation_input = 0;
                    case "Wilcoxon"
                        test_name = "wilcoxon";
                        test_display_name = "Wilcoxon Rank Sum";
                        ranking_statistic = "z_statistic";
                        is_noncorrelation_input = 0;
                    case "Cohen's D"
                        d = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                        d.v = result_struct.perm_net_results{result_number}.d.v;
                        single_sample_d = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                        single_sample_d.v = result_struct.perm_net_results{result_number}.within_np_d.v;
                end
                new_results_struct = struct(...
                    'test_name', test_name,...
                    "test_display_name", test_display_name,...
                    "ranking_statistic", ranking_statistic,...
                    "is_noncorrelation_input", is_noncorrelation_input,...
                    "permutation_count", result_struct.perm_net_results{result_number}.perm_count,...
                    "test_options", test_options...
                );
                no_permutation = struct();
                full_connectome = struct();
                within_network_pair = struct();
                if result_struct.perm_net_results{result_number}.has_nonpermuted
                    no_permutation.uncorrected_single_sample_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                    no_permutation.uncorrected_single_sample_p_value.v = result_struct.perm_net_results{result_number}.prob.v;
                end
                if result_struct.perm_net_results{result_number}.has_full_conn
                    if ~isequal(d, false)
                        full_connectome.d = d;
                    end
                    full_connectome.uncorrected_two_sample_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                    full_connectome.uncorrected_two_sample_p_value.v = result_struct.perm_net_results{result_number}.perm_prob.v;
                end
                if result_struct.perm_net_results{result_number}.has_within_net_pair
                    if ~isequal(single_sample_d, false)
                        within_network_pair.single_sample_d = single_sample_d;
                    end
                    within_network_pair.uncorrected_single_sample_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                    within_network_pair.uncorrected_single_sample_p_value.v = result_struct.perm_net_results{result_number}.within_np_prob.v;
                end
                new_results_struct.no_permutation = no_permutation;
                new_results_struct.full_connectome = full_connectome;
                new_results_struct.within_network_pair = within_network_pair;
                converted_data_struct.permutation_network_test_results = [converted_data_struct.permutation_network_test_results new_results_struct];
            end            
        end

        function [previous_result_data, old_data] = loadPreviousData(file)
            import nla.net.result.NetworkTestResult

            try        
                results_file = load(file);
                
                % This shouldn't happen, but just in case...
                if isa(results_file.results, 'nla.ResultPool') && ~(isfield(results_file.results_as_struct, 'net_atlas') && isfield(results_file.results_as_struct, 'input_struct'))
                    previous_result_data = results_file.results;  
                    old_data = false;
                else
                    
                    % Turn off some warnings we know are going to trigger with old results
                    warning('off', 'MATLAB:class:EnumerationNameMissing');
                    warning('off', 'MATLAB:load:classNotFound');
                    previous_result_struct = NetworkTestResult().loadOldVersionData(results_file.results_as_struct);
                    previous_result_struct_edge_class = NetworkTestResult().edgeResultsStructToClasses(previous_result_struct);
                    previous_result_struct_class = NetworkTestResult().permutationResultsStructToClasses(previous_result_struct_edge_class);
                    previous_result_data = nla.ResultPool();
                    props = properties(previous_result_data);
                    for prop = 1:numel(props)
                        if isfield(previous_result_struct_class, props{prop})
                            previous_result_data.(props{prop}) = previous_result_struct_class.(props{prop});
                        end
                    end
                    old_data = true;
                end
            catch 
                error("Failure to load results file");
            end
            warning('on', 'MATLAB:class:EnumerationNameMissing');
            warning('on', 'MATLAB:load:classNotFound');
        end

        function class_results = permutationResultsStructToClasses(structure_in)
            new_network_results = cell(1,numel(structure_in.permutation_network_test_results));
            for result = 1:numel(structure_in.permutation_network_test_results)
                network_result = nla.net.result.NetworkTestResult();
                fields = fieldnames(network_result);
                for field_index = 1:numel(fields)
                    if isfield(structure_in.permutation_network_test_results{result}, (fields{field_index})) && ~isequal(fields{field_index}, "test_methods")
                        network_result.(fields{field_index}) = structure_in.permutation_network_test_results{result}.(fields{field_index});
                    end
                end
                new_network_results{result} = network_result;
            end
            structure_in.permutation_network_test_results = new_network_results;
            class_results = structure_in;
        end

        function class_results = edgeResultsStructToClasses(structure_in)
            edge_result = nla.edge.result.Base();
            fields = fieldnames(edge_result);
            for field_index = 1:numel(fields)
                if isfield(structure_in.edge_test_results, fields{field_index})
                    if isequal(fields{field_index}, "coeff") || isequal(fields{field_index}, "prob") || isequal(fields{field_index}, "prob_sig")
                        edge_result.(fields{field_index}) = nla.TriMatrix(structure_in.edge_test_results.coeff.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                        edge_result.(fields{field_index}).v = structure_in.edge_test_results.(fields{field_index}).v;
                    else
                        edge_result.(fields{field_index}) = structure_in.edge_test_results.(fields{field_index});
                    end
                end
            end
            structure_in.edge_test_results = edge_result;
            class_results = structure_in;
        end
    end
end