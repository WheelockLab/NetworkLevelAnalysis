classdef WelchTTest < handle
    %WELCHTTEST Welch's t-Test (t-test assuming normal distributions with unequal variances)

    properties (Constant)
        name = "welchs_t"
        display_name = "Welch's T-test"
        statistics = ["t_statistic", "single_sample_t_statistic"]
        ranking_statistic = "t_statistic"
    end

    methods 
        function obj = WelchTTest()
        end

        function result = run(obj, test_options, edge_test_results, network_atlas, permutations)
            %RUN runs the Welch's t-test
            %  test_options: The selected values for the test to be run. Formerly input_struct. Options are in nla.net.genBaseInputs
            %  edge_test_results: Non-permuted edge test results. Formerly edge_result
            %  network_atlas: Network atlas for data
            %  test_type: Welch's (welchs) or Student's (students) t-test (default: students)

            import nla.TriMatrix nla.TriMatrixDiag

            number_of_networks = network_atlas.numNets();

            % Store results in the 'no_permutations' structure if this is the no-permutation test
            permutation_results = "no_permutations";
            t_statistic = "t_statistic";
            p_value = "uncorrected_two_sample_p_value";
            single_sample_p_value = "uncorrected_single_sample_p_value";
            single_sample_t_statistic = "single_sample_t_statistic";
            if isequal(permutations, true)
                % Otherwise, add it on to the back of the 'permutation_results' structure
                permutation_results = "permutation_results";
                p_value = "two_sample_p_value_permutations";
                t_statistic = strcat(t_statistic, "_permutations");
                single_sample_p_value = "single_sample_p_value_permutations";
                single_sample_t_statistic = strcat(single_sample_t_statistic, "_permutations");
            end

            result = nla.net.result.NetworkTestResult(test_options, number_of_networks, obj.name, obj.display_name, obj.statistics, obj.ranking_statistic);

            % Double for-loop to iterate through trimatrix. Network is the row, network2 the column. Since
            % we only care about the bottom half, second for-loop is 1:network
            for network = 1:number_of_networks
                for network2 = 1:network
                    network_rho = edge_test_results.coeff.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network2).indexes);

                    [p, t_stat, ~] = nla.welchT(network_rho, edge_test_results.coeff.v);
                    [~, single_sample_p, ~, single_sample_stats] = ttest(network_rho);


                    result.(permutation_results).(p_value).set(network, network2, p);
                    result.(permutation_results).(t_statistic).set(network, network2, t_stat);

                    result.(permutation_results).(single_sample_p_value).set(network, network2, single_sample_p);
                    result.(permutation_results).(single_sample_t_statistic).set(network, network2, single_sample_stats.tstat);
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