classdef NetworkTestResult < handle
    %NETWORKTESTRESULT Network Test Results
    % This is the super class that all network test results will be in
    % When a result is created the three repositories (within_network_pair, full_connectome, no_permutations) are set
    % to false. This makes it easier to do an if/else check on them. 
    % The three private methods create the structures and trimatrices to keep the data.
    % Output object:
    %   test_name: The name of the network test run (chi_squared, hypergeometric, etc)
    %   test_options: The options passed in. Method, plotting methods (formerly input_struct)
    %   within_network_pair: Results from within_network_pair tests
    %   full_connectome: Results from full_connectome tests
    %   no_permutations: Results from the no permutation test
    %
    % Within each of the three results structures will be properties containing the tri-matrices. Each test is different,
    % but all contain:
    %   p_value: TriMatrix with p-values
    %   p_value_permutations: TriMatrix with all the p-value permutations
    %   single_sample_p_value: TriMatrix with the single sample p-value (if available)
    %   single_sample_p_value_permutations: TriMatrix with single sample p-value permutations
    %
    properties
        test_name = "" % Name of the network test run
        test_options = struct() % Options selected for the test. Formerly input_struct
        within_network_pair = false % Results for within-network-pair tests
        full_connectome = false % Results for full connectome tests (formerly 'experiment wide')
        no_permutations = false % Results for the network tests with no permutations (the 'observed' results)        
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
                other_object = other_objects{object_index};

                for method_index = 1:numel(obj.test_methods)
                    test_method = obj.test_methods(method_index);
                    statistic_prefix = "obj.(test_method)";

                    if obj.(test_method)                       
                        test_statistics = fieldnames(other_object.(test_method));
                        % Iterate through all the statistics
                        % This is messy. Choice has to be made between wordy code of a million .m files for classes
                        % Damn you, Matlab! Multiple classes in a file should be easy!
                        for statistic_index = 1:numel(test_statistics)
                            test_statistic = test_statistics{statistic_index};
                            % This merge method really just merges all the permutation data together. The observed
                            % statistics should be the same 
                            if contains(other_object.(test_method).(test_statistic), "_permutations")
                                obj.(test_method).(test_statistic).v = [(statistic_prefix).(test_statistic).v,...
                                    other_object.(test_method).(test_statistic).v];
                            end
                        end
                    end
                end
            end
        end

        function concatenateResult(obj, other_object)
            %CONCATENATERESULT Add a result to the back of a TriMatrix. Used to keep permutation data. Ordered

            if ~all({obj.no_permutations, obj.within_network_pair, obj.full_connectome})
                for method_index = 1:numel(obj.test_methods)
                    test_method = obj.test_methods(test_method_index);
                    if other_object.(test_method)
                        obj = nla.net2.result.NetworkTestResult(other_object.test_options, other_object.(test_method).p_value.size,...
                            other_object.test_name, fieldnames(other_object.(test_method)));
                    end
                end
            end

            for method_index = 1:numel(obj.test_methods)
                test_method = obj.test_methods(method_index);
                statistic_prefix = obj.(test_method);

                (statistic_prefix).p_value_permutations.v(:, obj.last_index + 1) = other_object.(test_method).p_value.v;
                if ~isempty(other_object.(test_method).single_sample_p_value)
                    (statistic_prefix).single_sample_p_value_permutations.v(:, obj.last_index + 1) = other_object.(test_method).single_sample_p_value.v;
                end
                    
                test_specific_statistics = fieldnames(obj.(test_method));
                for statistic_index = 1:numel(test_specific_statistics)
                    test_statistic = test_specific_statistics{statistic_index};
                    if ~contains(other_object.(test_method).(test_statistic), "_permutations")
                        (statistic_prefix).(strcat(test_statistic, "_permutations")).v(:, obj.last_index + 1) =...
                            other_object.(test_method).(test_statistic).v;
                    end
                end

                obj.last_index = obj.last_index + 1;
            end
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

            for test_method_index = numel(obj.test_methods)
                test_method = obj.test_methods(test_method_index);
                if obj.(test_method)
                    for statistic_index = 1:numel(test_specific_statistics)
                        test_statistic = test_specific_statistics(statistic_index);
                        obj.(test_method).(test_statistic) = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                    end
                end
            end
        end

        function createPValueTriMatrices(obj, number_of_networks, test_method)
            %CREATEPVALUETRIMATRICES Creates the p-value substructure for the test method

            import nla.TriMatrix nla.TriMatrixDiag

            % I could've looped this, too. Just copy/paste from earlier, so it stays. Plus, this is every test regardless of test or method
            obj.(test_method).p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            obj.(test_method).p_value_permutations = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            obj.(test_method).single_sample_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            obj.(test_method).single_sample_p_value_permutations = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
        end
    end
end