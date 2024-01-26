classdef ChiSquaredTest < handle
    %CHISQUARED Chi-squared test to determine how far a result is from expectation
    properties (Constant)
        name = "chi_squared"
        display_name = "Chi-Squared"
        statistics = ["chi2_statistic", "greater_than_expected"]
        ranking_statistic = "chi2_statistic"
    end

    methods
        function obj = ChiSquaredTest()
        end

        function result = run(obj, test_options, edge_test_results, network_atlas, permutations)
            %RUN runs the chi-squared test
            %  test_options: The selected values for the test to be run. Formerly input_struct. Options are in nla.net.genBaseInputs
            %  edge_test_results: Non-permuted edge test results. Formerly edge_result
            %  network_atlas: Network atlas for data

            import nla.TriMatrix nla.TriMatrixDiag

            % Store results in the 'no_permutations' structure if this is the no-permutation test
            permutation_results = "no_permutations";
            chi2_statistic = "chi2_statistic";
            greater_than_expected = "greater_than_expected";
            if isequal(permutations, true)
                % Otherwise, add it on to the back of the 'permutation_results' structure
                permutation_results = "permutation_results";
                chi2_statistic = strcat(chi2_statistic, "_permutations");
                greater_than_expected = strcat(greater_than_expected, "_permutations");
            end

            number_of_networks = network_atlas.numNets();

            % Structure to pass results outside
            result = nla.net.result.NetworkTestResult(test_options, number_of_networks, obj.name, obj.display_name,...
                obj.statistics);

            % Empty this out since it is not needed
            result.(permutation_results).(chi2_statistic) = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            result.(permutation_results).(greater_than_expected) = TriMatrix(number_of_networks, "logical", TriMatrixDiag.KEEP_DIAGONAL);

            % Double for-loop to iterate through trimatrix. Network is the row, network2 the column. Since
            % we only care about the bottom half, second for-loop is 1:network
            for network = 1:number_of_networks
                for network2 = 1:network
                    network_pair_ROI_significance = edge_test_results.prob_sig.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network2).indexes);
                    network_ROI_count = numel(network_pair_ROI_significance);
                    observed_significance = sum(network_pair_ROI_significance);
                    expected_significance = edge_test_results.avg_prob_sig * network_ROI_count;
                    chi2_value = ((observed_significance - expected_significance) .^ 2) .* ((expected_significance .^ -1)); %legacy style, AS 240529
                    result.(permutation_results).(chi2_statistic).set(network, network2, chi2_value);
                    result.(permutation_results).(greater_than_expected).set(network, network2, observed_significance > expected_significance);
                end
            end

            % If the observed value is not greater than the expected, we zero out the result
            % This just results in a p-value of 1. Which means no difference between chance and null
            % hypothesis. We also zero anything that isn't finite to be safe
            result.(permutation_results).(chi2_statistic).v(~result.(permutation_results).(greater_than_expected).v) = 0;
            result.(permutation_results).(chi2_statistic).v(~isfinite(result.(permutation_results).(chi2_statistic).v)) = 0;

            % Matlab function for chi-squared cdf to get p-value. "Upper" calculates the upper tail instead of
            % using 1 - lower tail
            if permutations
                result.permutation_results.p_value_permutations.v = chi2cdf(result.permutation_results.chi2_statistic_permutations.v, 1, "upper");
            else
                result.no_permutations.p_value.v = chi2cdf(result.no_permutations.chi2_statistic.v, 1, "upper");
            end
        end
    end

    methods (Static)
        function inputs = requiredInputs()
            inputs = {nla.inputField.Integer('behavior_count', 'Test count:', 1, 1, Inf), nla.inputField.Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1)};
        end
    end
end