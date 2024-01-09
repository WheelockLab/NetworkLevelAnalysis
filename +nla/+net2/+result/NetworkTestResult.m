classdef NetworkTestResult < handle
    %NETWORKTESTRESULT Network Test Results
    % This is the super class that all network test results will be inheriting from
    properties
        test_name = "" % Name of the network test run
        p_value = false % TriMatrix of p-values for network tests
        p_value_permutations = false % Multiple TriMatrices (one of each permutation) of p-values for network tests
        single_sample_p_value = false % TriMatrix of single sample p-values
        single_sample_p_value_permutations = false % Multiple TriMatrices of single sample p-values
        test_statistics = struct("chi_squared", struct(),...
            "hypergeometric", struct(),...
            "kolmogorov_smirnov", struct(),...
            "welchs_t", struct(),...
            "students_t", struct(),...
            "wilcoxon", struct()...
        ) % Structure to hold individual test result statistics
    end

    properties (Access = private)
        last_index = 0;
    end

    methods
        function obj = NetworkTestResult(number_of_networks, test_name, test_specific_statistics)
            %CONSTRUCTOR Used for creating results.
            %
            % Arguments:
            %   number_of_networks: The number of networks in the data being analyzed
            %   test_name: The name of the network test being run
            %   test_specific_statistics: Test statistics for a test. (Example: t_statistic for a t-Test)
            import nla.TriMatrix nla.TriMatrixDiag

            if nargin == 3
                obj.test_name = test_name;
                obj.p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                obj.p_value_permutations = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                obj.single_sample_p_value = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                obj.single_sample_p_value_permutations = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
                % Create containers for all test specific statistics and all their permutations
                for statistic_index = 1:numel(test_specific_statistics)
                    obj.test_statistics.(test_name).(test_specific_statistics(statistic_index)) = [];
                    obj.test_statistics.(test_name).(strcat((test_specific_statistics(statistic_index)), "_permutations")...
                        ) = [];
                end
            else
                error("NetworkTestResults requires 3 arguments: Number of Networks, Test Name, Test Statistics")
            end
        end

        function merge(obj, other_objects)
            %MERGE Merge two groups of results together. Not guaranteed to be ordered
            for object_index = 1:numel(other_objects)
                other_object = other_objects{object_index};
                obj.p_value_permutations.v = [obj.p_value_permutations.v, other_object.p_value_permutations.v];
                
                test_specific_statistics = fieldnames(obj.test_statistics.(obj.test_name));
                % Iterate through all the test specific states
                % This is messy. Choice has to be made between wordy code of a million .m files for classes
                % Damn you, Matlab! Multiple classes in a file should be easy!
                for statistic_index = 1:numel(test_specific_statistics)
                    test_statistic = test_specific_statistics{statistic_index};
                    if contains(other_object.test_statistics.(obj.test_name).(test_statistic), "_permutations")
                        obj.test_statistics.(obj.test_name).(test_statistic).v = [...
                            obj.test_statistics.(obj.test_name).(test_statistic).v,...
                            other_object.test_statistics.(obj.test_name).(test_statistic).v...
                        ];
                    end
                end
            end
        end

        function concatenateResult(obj, other_object)
            %CONCATENATERESULT Add a result to the back of a TriMatrix. Used to keep permutation data. Ordered
            if isempty(obj.p_value)
                obj = nla.net2.result.NetworkTestResult(...
                    other_object.p_value.size, other_object.(obj.test_name), fieldnames(other_object.test_statistics.(obj.test_name)));
            end
            obj.p_value_permutations.v(:, obj.last_index + 1) = other_object.p_value.v;
            if ~isempty(other_object.single_sample_p_value)
                obj.single_sample_p_value_permutations.v(:, obj.last_index + 1) = other_object.single_sample_p_value.v;
            end
                
            test_specific_statistics = fieldnames(obj.test_statistics.(obj.test_name));
            for statistic_index = 1:numel(test_specific_statistics)
                test_statistic = test_specific_statistics{statistic_index};
                if ~contains(other_object.test_statistics.(obj.test_name).(test_statistic), "_permutations")
                    obj.test_statistics.(obj.test_name).(strcat(test_statistic, "_permutations")).v(:, obj.last_index + 1) =...
                        other_object.test_statistics.(obj.test_name).(test_statistic).v;
                end
            end

            obj.last_index = obj.last_index + 1;
        end
    end
end