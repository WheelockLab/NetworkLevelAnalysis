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
        test_options = struct() % Options selected for the test. Formerly input_struct
        within_network_pair = false % Results for within-network-pair tests
        full_connectome = false % Results for full connectome tests (formerly 'experiment wide')
        no_permutations = false % Results for the network tests with no permutations (the 'observed' results)    
        permutation_results = false % Results for each permutation test used to calculate p-values for the test methods    
    end

    properties (Access = private)
        last_index = 0
    end

    properties (Constant)
        test_methods = ["no_permutations", "within_network_pair", "full_connectome"]
    end

    methods
        function obj = NetworkTestResult(test_options, number_of_networks, test_name, test_specific_statistics)
            %CONSTRUCTOR Used for creating results.
            %
            % Arguments:
            %   test_options [Struct]: Options for the test. Formerly 'input_struct'
            %   number_of_networks [Int]: The number of networks in the data being analyzed
            %   test_name [String]: The name of the network test being run
            %   test_specific_statistics [Array[String]]: Test statistics for a test. (Example: t_statistic for a t-Test)

            import nla.TriMatrix nla.TriMatrixDiag

            if nargin == 4
                obj.test_name = test_name;
                obj.test_options = test_options;

                obj.createResultsStorage(number_of_networks, test_specific_statistics)
            else
                error("NetworkTestResults requires 4 arguments: Test Options, Number of Networks, Test Name, Test Statistics")
            end
        end

        function merge(obj, other_objects)
            %MERGE Merge two groups of results together. Not guaranteed to be ordered
            for object_index = 1:numel(other_objects)
                % These are the names of the statistics in permutation_results. We only really need to merge the permutation results,
                % all the other results will be 2D while the permutation results are 3D
                statistics = fieldnames(other_objects{object_index}.permutation_results);
                for statistic_index = 1:numel(statistics)
                    obj.permutation_results.(statistics(statistic_index)).v = [obj.permutation_results.(statistics(statistic_index)).v,...
                        other_objects{object_index}.permutation_results.(statistics(statistic_index)).v];
                end
            end
        end

        function concatenateResult(obj, other_object)
            %CONCATENATERESULT Add a result to the back of a TriMatrix. Used to keep permutation data. Ordered

            % Check to make sure we've created an object and create one if we haven't
            if ~all({obj.no_permutations, obj.within_network_pair, obj.full_connectome})
                for method_index = 1:numel(obj.test_methods)
                    test_method = obj.test_methods(test_method_index);
                    if other_object.(test_method)
                        obj = nla.net2.result.NetworkTestResult(other_object.test_options, other_object.(test_method).p_value.size,...
                            other_object.test_name, fieldnames(other_object.(test_method)));
                    end
                end
            end

            statistics = fieldnames(obj.permutation_results);
            for statistic_index = 1:numel(statistics)
                statistic_name = statistics(statistic_index);
                if obj.permutation_results.(statistic_name)
                    obj.permutation_results.(statistic_name).v(:, obj.last_index + 1) = other_object.permutation_results.(statistic_name).v;
                end
            end

            obj.last_index = obj.last_index + 1;
        end
    end

    methods (Access = private)
        function createResultsStorage(obj, number_of_networks, test_specific_statistics)
            %CREATERESULTSSTORAGE Create the substructures for the methods chosen
            %   For example: 
            %       Within Network Pair test
            %       NetworkTestResult.within_network_pair = {p_value, p_value_permutations, etc etc}
            %   Any test method not being run will be an empty structure

            % Our 3 test methods. No permutations, Within-Network-Piar, Full Connectome
            % Creating an array of pairs status (yes/no) and name for the results (Find a better way, code-monkey)
            test_methods_and_names = [{obj.test_options.nonpermuted, "no_permutations"};...
                {obj.test_options.within_net_pair, "within_network_pair"};...
                {obj.test_options.full_conn, "full_connectome"}];

            % Calling function to create results containers
            for test_method_index = 1:3
                if test_methods_and_names(test_method_index, 1)
                    obj.createPValueTriMatrices(number_of_networks, test_methods_and_names(test_method_index, 2))
                    obj.createTestSpecificResultsStorage(number_of_networks, test_specific_statistics);
                end
            end
        end

        function createTestSpecificResultsStorage(obj, number_of_networks, test_specific_statistics)
            %CREATETESTSPECIFICRESULTSSTORAGE Create the substructures for the specific statistical tests

            import nla.TriMatrix nla.TriMatrixDiag

            obj.permutation_results.p_value_permutations = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            obj.permutation_results.single_sample_p_value_permutations = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);

            for statistic_index = 1:numel(test_specific_statistics)
                test_statistic = test_specific_statistics(statistic_index);
                obj.permutation_results.(strcat(test_statistic, "_permutations")) = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            end
        end

        function createPValueTriMatrices(obj, number_of_networks, test_method)
            %CREATEPVALUETRIMATRICES Creates the p-value substructure for the test method

            import nla.TriMatrix nla.TriMatrixDiag

            % I could've looped this, too. Just copy/paste from earlier, so it stays. Plus, this is every test regardless of test or method
            obj.(test_method).p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            obj.(test_method).single_sample_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
        end
    end
end