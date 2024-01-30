classdef WilcoxonTest < handle
    %WILCOXON Wilcoxon rank sum test
    properties (Constant)
        name = "wilcoxon"
        display_name = "Wilcoxon Rank Sum"
        statistics = ["ranksum_statistic", "single_sample_ranksum_statistic", "z_statistic"]
        ranking_statistic = "z_statistic"
    end

    methods
        function obj = WilcoxonTest()
        end

        function result = run(obj, test_options, edge_test_results, network_atlas, permutations)
            %RUN runs the Wilcoxon rank-sum test
            %  test_options: The selected values for the test to be run. Formerly input_struct. Options are in nla.net.genBaseInputs
            %  edge_test_results: Non-permuted edge test results. Formerly edge_result
            %  network_atlas: Network atlas for data

            import nla.TriMatrix nla.TriMatrixDiag

            number_of_networks = network_atlas.numNets();

            % Store results in the 'no_permutations' structure if this is the no-permutation test
            permutation_results = "no_permutations";
            p_value = "p_value";
            ranksum_statistic = "ranksum_statistic";
            z_statistic = "z_statistic";
            single_sample_p_value = "single_sample_p_value";
            single_sample_ranksum_statistic = "single_sample_ranksum_statistic";
            if isequal(permutations, true)
                % Otherwise, add it on to the back of the 'permutation_results' structure
                permutation_results = "permutation_results";
                p_value = strcat(p_value, "_permutations");
                ranksum_statistic = strcat(ranksum_statistic, "_permutations");
                z_statistic = strcat(z_statistic, "_permutations");
                single_sample_p_value = strcat(single_sample_p_value, "_permutations");
                single_sample_ranksum_statistic = strcat(single_sample_ranksum_statistic, "_permutations");
            end

            result = nla.net.result.NetworkTestResult(test_options, number_of_networks, obj.name, obj.display_name, obj.statistics);

            % Double for-loop to iterate through trimatrix. Network is the row, network2 the column. Since
            % we only care about the bottom half, second for-loop is 1:network
            for network = 1:number_of_networks
                for network2 = 1:network
                    network_rho = edge_test_results.coeff.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network2).indexes);

                    [p, ~, stats] = ranksum(network_rho, edge_test_results.coeff.v);
                    result.(permutation_results).(p_value).set(network, network2, p);
                    result.(permutation_results).(ranksum_statistic).set(network, network2, stats.ranksum);
                    result.(permutation_results).(z_statistic).set(network, network2, stats.zval);
                    
                    [single_sample_p, ~, single_sample_stats] = signrank(network_rho);
                    result.(permutation_results).(single_sample_p_value).set(network, network2, single_sample_p);
                    result.(permutation_results).(single_sample_ranksum_statistic).set(network, network2, single_sample_stats.signedrank);
                end
            end
        end
    end

    methods (Static)
        function inputs = requiredInputs()

            inputs = {...
                nla.inputField.Integer('behavior_count', 'Test count:', 1, 1, Inf),...
                nla.inputField.Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1),...
            };
        end
    end
end