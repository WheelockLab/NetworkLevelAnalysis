classdef NetworkTestResult < handle
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
        significance_test_names = ["chi_squared", "hypergeometric"]
    end

    methods
        function obj = NetworkTestResult(test_options, number_of_networks, test_name, test_display_name, test_specific_statistics)
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
            %CONCATENATERESULT Add a result to the back of a TriMatrix. Used to keep permutation data. Ordered

            % Check to make sure we've created an object and create one if we haven't
            % if ~isfield(obj.permutation_results, 'p_value_permutations')
            %     obj = nla.net.result.NetworkTestResult(other_object.test_options, other_object.(test_method).p_value.size,...
            %         other_object.test_name, fieldnames(other_object.(test_method)));
            %     % Set last index to zero since this is the concatenated data will be the initial data
            %     obj.last_index = 0;
            % end

            statistics = fieldnames(obj.permutation_results);
            for statistic_index = 1:numel(statistics)
                statistic_name = statistics(statistic_index);
                if ~isempty(obj.permutation_results.(statistic_name{1}))
                    obj.permutation_results.(statistic_name{1}).v(:, obj.last_index + 1) = other_object.permutation_results.(statistic_name{1}).v;
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
            %   For example: 
            %       Within Network Pair test
            %       NetworkTestResult.within_network_pair = {p_value, p_value_permutations, etc etc}
            %   Any test method not being run will be an empty structure

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
                obj.permutation_results.(strcat(test_statistic, "_permutations")) = TriMatrix(number_of_networks,...
                    TriMatrixDiag.KEEP_DIAGONAL);
            end
        end

        function createPValueTriMatrices(obj, number_of_networks, test_method)
            %CREATEPVALUETRIMATRICES Creates the p-value substructure for the test method

            import nla.TriMatrix nla.TriMatrixDiag

            % I could've looped this, too. Just copy/paste from earlier, so it stays. Plus, this is every test 
            % regardless of test or method
            obj.(test_method) = struct();
            obj.(test_method).p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            obj.(test_method).single_sample_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
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