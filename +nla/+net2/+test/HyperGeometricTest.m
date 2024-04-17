classdef HyperGeometricTest < handle
    %HYPERGEOMETRICTEST Hypergeometric (One-sided Fisher's Exact Test) to test significance
    properties (Constant)
        name = "hypergeometric"
        statistics = ["greater_than_expected"]
    end

    methods
        function obj = HyperGeometricTest()
        end

        function result = run(obj, test_options, edge_test_results, network_atlas)
            %RUN runs the hypergeometric test
            %  test_options: The selected values for the test to be run. Formerly input_struct. Options are in nla.net.genBaseInputs
            %  edge_test_results: Non-permuted edge test results. Formerly edge_result
            %  network_atlas: Network atlas for data
            
            import nla.TriMatrix nla.TriMatrixDiag

            number_of_networks = network_atlas.numNets();

            % Container to hold results
            result = nla.net2.result.NetworkTestResult(test_options, number_of_networks, obj.name, obj.statistics);
            % Empty this out since it is not needed
            result.permutation_results.single_sample_p_value = false;
            result.permutation_results.greated_than_expected = TriMatrix(number_of_networks, "logical", TriMatrixDiag.KEEP_DIAGONAL);

            % Double for-loop to iterate through trimatrix. Network is the row, network2 the column. Since
            % we only care about the bottom half, second for-loop is 1:network
            for network = 1:number_of_networks
                for network2 = 1:network
                    network_pair_ROI_significance = edge_test_results.prob_sig.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network2).indexes);
                    network_ROI_count = numel(network_pair_ROI_significance);
                    observed_significance = sum(network_pair_ROI_significance);
                    expected_significance = edge_test_results.avg_prob_sig * network_ROI_count;
                    result.permutation_results.greated_than_expected.set(network, network2, observed_significance > expected_significance)
                    % Matlab function for hypergeometric cdf to get p-value. "Upper" calculates the upper tail instead of
                    % using 1 - lower tail
                    result.permutation_results.p_value.set(network, network2, hygecdf(observed_significance, numel(edge_test_results.prob_sig.v),...
                        sum(edge_test_results.prob), network_ROI_count, "upper"));
                end
            end

            % If the observed value is not greater than the expected, we zero out the result
            % This just results in a p-value of 1. Which means no difference between chance and null
            % hypothesis.
            result.permutation_results.p_value.v(~result.permutation_results.greated_than_expected.v) = 1;
        end
    end
end