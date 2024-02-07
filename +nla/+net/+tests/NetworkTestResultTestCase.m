classdef NetworkTestResultTestCase < matlab.unittest.TestCase

    properties
        number_of_networks
        test_data
        test_options
        test
    end

    methods (TestMethodSetup)
        function loadInputData(testCase)
            import nla.TriMatrix nla.TriMatrixDiag nla.net.test.WilcoxonTest nla.net.result.NetworkTestResult
            testCase.number_of_networks = 15;
            testCase.test_data = TriMatrix(testCase.number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            testCase.test_data.v = rand(size(testCase.test_data.v));
            testCase.test_options = struct("within_net_pair", true, "full_conn", true, "nonpermuted", true);
            testCase.test = WilcoxonTest();
        end
    end

    methods (TestMethodTeardown)
        function clearData(testCase)
            clear testCase.number_of_networks;
            clear testCase.test_data;
            clear testCase.test_options;
            clear testCase.test;
        end
    end

    methods (Test)
        function NetworkTestResultCreationTest(testCase)
            import nla.net.result.NetworkTestResult
         
            results = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            testCase.verifyInstanceOf(results, ?nla.net.result.NetworkTestResult);
            testCase.verifyEqual(results.test_name, testCase.test.name);
            testCase.verifyEqual(results.test_options, testCase.test_options);
        end

        function NetworkTestResultNoPermutationsTest(testCase)
            import nla.net.result.NetworkTestResult
         
            results = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            % The size of TriMatrices are cast to uint32. Is there a good reason for this?
            testCase.verifyEqual(results.no_permutations.p_value.size, uint32(testCase.number_of_networks));
        end

        function NetworkTestResultWithinNetworkPairTest(testCase)
            import nla.net.result.NetworkTestResult
         
            results = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            % The size of TriMatrices are cast to uint32. Is there a good reason for this?
            testCase.verifyEqual(results.within_network_pair.p_value.size, uint32(testCase.number_of_networks));
        end

        function NetworkTestResultFullConnectomeTest(testCase)
            import nla.net.result.NetworkTestResult
         
            results = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            % The size of TriMatrices are cast to uint32. Is there a good reason for this?
            testCase.verifyEqual(results.full_connectome.p_value.size, uint32(testCase.number_of_networks));
        end

        function NetworkTestResultPermutationResultsTest(testCase)
            import nla.net.result.NetworkTestResult
         
            results = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            % The size of TriMatrices are cast to uint32. Is there a good reason for this?
            testCase.verifyEqual(results.permutation_results.p_value_permutations.size, uint32(testCase.number_of_networks));
        end

        function NetworkTestResultPermutationsTest(testCase)
            import nla.net.result.NetworkTestResult

            results = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            testCase.test_data.v(:, 2) = testCase.test_data.v;
            testCase.test_data.v(:, 3) = testCase.test_data.v(:, 1);
            
            results.permutation_results.p_value_permutations.v = testCase.test_data.v;
            testCase.verifyEqual(results.permutation_count, size(testCase.test_data.v, 2));
        end

        function NetworkTestResultMergeTest(testCase)
            import nla.net.result.NetworkTestResult

            results = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            results.permutation_results.p_value_permutations.v = testCase.test_data.v;

            results2 = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            results2.permutation_results.p_value_permutations.v = (testCase.test_data.v) .* 2;

            results.merge(results2);
            results.permutation_results.single_sample_p_value_permutations.v
            testCase.verifyEqual(results.permutation_results.p_value_permutations.v,...
                [testCase.test_data.v, (testCase.test_data.v) .* 2]);
        end

        function NetworkTestResultConcatenateResultTest(testCase)
            import nla.net.result.NetworkTestResult

            results = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            results.permutation_results.p_value_permutations.v = testCase.test_data.v;

            results2 = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            results2.permutation_results.p_value_permutations.v = (testCase.test_data.v) .* 2;
            results.concatenateResult(results2);

            concatenated_results = NetworkTestResult(testCase.test_options, testCase.number_of_networks, testCase.test.name,...
                testCase.test.display_name, testCase.test.statistics);
            concatenated_results.permutation_results.p_value_permutations.v = results.permutation_results.p_value_permutations.v;
            concatenated_results.permutation_results.p_value_permutations.v(:, 2) = results2.permutation_results.p_value_permutations.v;
            testCase.verifyEqual(results.test_name, concatenated_results.test_name);
            testCase.verifyEqual(results.permutation_results.p_value_permutations, concatenated_results.permutation_results.p_value_permutations);
        end
    end
end