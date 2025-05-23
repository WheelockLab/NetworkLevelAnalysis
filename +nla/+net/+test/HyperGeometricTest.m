classdef HyperGeometricTest < handle
    %HYPERGEOMETRICTEST Hypergeometric (One-sided Fisher's Exact Test) to test significance
    properties (Constant)
        name = "hypergeometric"
        display_name = "Hypergeometric"
        statistics = ["two_sample_p_value", "greater_than_expected"]
        ranking_statistic = "two_sample_p_value"
    end

    methods
        function obj = HyperGeometricTest()
        end

        function result = run(obj, test_options, edge_test_results, network_atlas, permutations)
            %RUN runs the hypergeometric test
            %  test_options: The selected values for the test to be run. Formerly input_struct. Options are in nla.net.genBaseInputs
            %  edge_test_results: Non-permuted edge test results. Formerly edge_result
            %  network_atlas: Network atlas for data
            
            import nla.TriMatrix nla.TriMatrixDiag

            number_of_networks = network_atlas.numNets();

            % Store results in the 'no_permutations' structure if this is the no-permutation test
            permutation_results = "no_permutations";
            greater_than_expected = "greater_than_expected";
            p_value = "two_sample_p_value";
            if isequal(permutations, true)
                % Otherwise, add it on to the back of the 'permutation_results' structure
                permutation_results = "permutation_results";
                greater_than_expected = strcat(greater_than_expected, "_permutations");
                p_value = "two_sample_p_value_permutations";
            end

            % Container to hold results
            % Pass a blank string as ranking statistic since Hypergeometric doesn't have one and we'll be skipping it
            result = nla.net.result.NetworkTestResult(test_options, number_of_networks, obj.name, obj.display_name, obj.statistics, obj.ranking_statistic); 

            % Double for-loop to iterate through trimatrix. Network is the row, network2 the column. Since
            % we only care about the bottom half, second for-loop is 1:network
            for network = 1:number_of_networks
                for network2 = 1:network
                    network_pair_ROI_significance = edge_test_results.prob_sig.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network2).indexes);
                    network_ROI_count = numel(network_pair_ROI_significance);
                    observed_hits = sum(network_pair_ROI_significance);
%                     expected_significance = edge_test_results.avg_prob_sig * network_ROI_count;
                    expected_hits = (sum(edge_test_results.prob_sig.v)/size(edge_test_results.prob_sig.v,1)) * network_ROI_count; % expected sig should be based off HITS, AS 250210
                    result.(permutation_results).(greater_than_expected).set(network, network2, observed_hits > expected_hits)
                    % Matlab function for hypergeometric cdf to get p-value. "Upper" calculates the upper tail instead of
                    % using 1 - lower tail
                    result.(permutation_results).(p_value).set(network, network2, hygecdf(observed_hits, numel(edge_test_results.prob_sig.v),...
                        sum(edge_test_results.prob_sig.v), network_ROI_count, "upper"));
                end
            end

            % If the observed value is not greater than the expected, we zero out the result
            % This just results in a p-value of 1. Which means no difference between chance and null
            % hypothesis.
            if permutations
                result.permutation_results.two_sample_p_value_permutations.v(~result.permutation_results.greater_than_expected_permutations.v) = 1;
            else
                result.no_permutations.uncorrected_two_sample_p_value = result.no_permutations.two_sample_p_value;
                result.no_permutations.uncorrected_two_sample_p_value.v(~result.no_permutations.greater_than_expected.v) = 1;
            end
        end
    end

    methods (Static)
        function inputs = requiredInputs()
            inputs = {nla.inputField.Integer('behavior_count', 'Test count:', 1, 1, Inf), nla.inputField.Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1)};
        end
    end
end