classdef ResultRankTestCase < matlab.unittest.TestCase
    properties
        result
        statistical_ranking = false
    end

    properties (Constant)
        number_of_networks = 15
        number_of_network_pairs = 120
        permutations = 9
    end

    methods (Test)
        function fullConnectomeRankTest(testCase)
            import nla.net.ResultRank nla.TriMatrix nla.TriMatrixDiag nla.net.result.NetworkTestResult

            % Initialize a result
            testCase.result = NetworkTestResult();
            testCase.result.no_permutations = struct();
            testCase.result.no_permutations.p_value = TriMatrix(testCase.number_of_networks,...
                TriMatrixDiag.KEEP_DIAGONAL);
            % Just fill it with 8's. 
            testCase.result.no_permutations.p_value.v(:) = 8;

            % 10 digits without 8. These are the permuted results
            permutation_vector = [[1:7], [9, 10, 11]];
            testCase.result.permutation_results.p_value_permutations = TriMatrix(testCase.number_of_networks, ...
                TriMatrixDiag.KEEP_DIAGONAL);
            % the vector of a 15 network trimatrix is 120. 1-11 without 8 is 10 digits. 12 repetitions
            testCase.result.permutation_results.p_value_permutations.v(:, 1) = repmat(permutation_vector, 1, 12);

            for permutation = 2:testCase.permutations
                % Here we're just randomizing things so we don't test the same vector over and over
                % It's still all the same 1-11 without 8, just mixing the order
                shifted_vector = circshift(permutation_vector, permutation-1);
                temp_result = NetworkTestResult();
                temp_result.permutation_results.p_value_permutations = TriMatrix(testCase.number_of_networks, ...
                    TriMatrixDiag.KEEP_DIAGONAL);
                temp_result.permutation_results.p_value_permutations.v = repmat(shifted_vector, 1, 12);
                testCase.result.concatenateResult(temp_result);
            end

            ranker = ResultRank(testCase.result, testCase.result, testCase.statistical_ranking,...
                testCase.number_of_network_pairs);
            ranker.permuted_network_results.full_connectome = struct();
            ranker.rank();
            expected = ones(1,120) * 0.7;
            % There are 756 numbers of 1-7, one 8, and 324 between 9-11. The 8 should be 757 every
            % time after they are sorted. 120 network pairs, 9 permutations =>
            % 757 / (1 + 120 * 9) = 0.7 
            % And we're rounding the result because it's easier than trying to get doubles to match
            testCase.verifyEqual(expected, round(ranker.permuted_network_results.full_connectome.p_value.v, 1));
        end

        function withinNetworkRankTest(testCase)
            import nla.net.ResultRank nla.TriMatrix nla.TriMatrixDiag nla.net.result.NetworkTestResult

            % Initialize a result
            testCase.result = NetworkTestResult();
            testCase.result.no_permutations = struct();
            testCase.result.no_permutations.p_value = TriMatrix(testCase.number_of_networks,...
                TriMatrixDiag.KEEP_DIAGONAL);
            testCase.result.no_permutations.p_value.v(:) = 8;

            % Here we're going with 1-10 without 8. This makes the math easier later. 8 / (1 + permutations) = 0.8. 
            % If we have 1-11 without 8 repeating, sometimes the 8 will be in the 8th place, sometimes it'll be 7th.
            permutation_vector = [[1:7], [9, 10]];
            testCase.result.permutation_results.single_sample_p_value_permutations = TriMatrix(testCase.number_of_networks, ...
                TriMatrixDiag.KEEP_DIAGONAL);
            % 14 repetitions, then we'll just cut some off
            % This becomes easier down the line
            temp_values = repmat(permutation_vector, 1, 14);
            testCase.result.permutation_results.single_sample_p_value_permutations.v(:, 1) = temp_values(1:120);

            for permutation = 2:testCase.permutations
                % Here we're just randomizing things so we don't test the same vector over and over
                shifted_vector = circshift(permutation_vector, permutation-1);
                temp_result = NetworkTestResult();
                temp_result.permutation_results.single_sample_p_value_permutations = TriMatrix(testCase.number_of_networks, ...
                    TriMatrixDiag.KEEP_DIAGONAL);
                shifted_vector = repmat(shifted_vector, 1, 14);
                temp_result.permutation_results.single_sample_p_value_permutations.v = shifted_vector(1:120);
                testCase.result.concatenateResult(temp_result);
            end

            ranker = ResultRank(testCase.result, testCase.result, testCase.statistical_ranking,...
                testCase.number_of_network_pairs);
            ranker.permuted_network_results.within_network_pair = struct();
            ranker.permuted_network_results.within_network_pair.single_sample_p_value =...
                TriMatrix(testCase.number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            ranker.rank();
            % Because of the way the arrays are shifted between 1-10, This is why we used 1-10 without 8 and removed values. The math works
            % out better on the searching here.
            expected = ones(1, 120) * 0.8;
            % No, I don't understand why the expected needs to be transposed here, either.
            testCase.verifyEqual(ranker.permuted_network_results.within_network_pair.single_sample_p_value.v, expected');
        end
    end
end