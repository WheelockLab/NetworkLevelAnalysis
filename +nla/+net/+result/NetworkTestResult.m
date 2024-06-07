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

        function output(obj, edge_test_options, updated_test_options, network_atlas, edge_test_result, flags)

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

        function set.is_noncorrelation_input(obj, ~)
        end

        function set.permutation_count(obj, ~)
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