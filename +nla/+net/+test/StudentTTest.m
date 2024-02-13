classdef StudentTTest < handle
    %STUDENTTTESTs Student's t-test (t-test assuming normal distributions)
    properties (Constant)
        name = "students_t"
        display_name = "Student's T-test"
        statistics = ["t_statistic", "single_sample_t_statistic"]
    end

    methods 
        function obj = StudentTTest()
        end

        function result = run(obj, test_options, edge_test_results, network_atlas, permutations)
            %RUN runs the Student's t-test
            %  test_options: The selected values for the test to be run. Formerly input_struct. Options are in nla.net.genBaseInputs
            %  edge_test_results: Non-permuted edge test results. Formerly edge_result
            %  network_atlas: Network atlas for data

            import nla.TriMatrix nla.TriMatrixDiag

            number_of_networks = network_atlas.numNets();

            % Store results in the 'no_permutations' structure if this is the no-permutation test
            permutation_results = "no_permutations";
            p_value = "p_value";
            t_statistic = "t_statistic";
            single_sample_p_value = "single_sample_p_value";
            single_sample_t_statistic = "single_sample_t_statistic";
            if permutations
                % Otherwise, add it on to the back of the 'permutation_results' structure
                permutation_results = "permutation_results";
                p_value = strcat(p_value, "_permutations");
                t_statistic = strcat(t_statistic, "_permutations");
                single_sample_p_value = strcat(single_sample_p_value, "_permutations");
                single_sample_t_statistic = strcat(single_sample_t_statistic, "_permutations");
            end

            result = nla.net.result.NetworkTestResult(test_options, number_of_networks, obj.name, obj.display_name,...
                obj.statistics);

            % Double for-loop to iterate through trimatrix. Network is the row, network2 the column. Since
            % we only care about the bottom half, second for-loop is 1:network
            for network = 1:number_of_networks
                for network2 = 1:network
                    network_rho = edge_test_results.coeff.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network2).indexes);
                    [~, p, ~, stats] = ttest2(network_rho, edge_test_results.coeff.v);

                    [~, single_sample_p, ~, single_sample_stats] = ttest(network_rho);

                    result.(permutation_results).(p_value).set(network, network2, p);
                    result.(permutation_results).(t_statistic).set(network, network2, stats.tstat);
                    result.(permutation_results).(single_sample_p_value).set(network, network2, single_sample_p);
                    result.(permutation_results).(single_sample_t_statistic).set(network, network2, single_sample_stats.tstat);
                end
            end
            
        end
    end

    methods (Static)
        function inputs = requiredInputs()
            inputs = {nla.inputField.Integer('behavior_count', 'Test count:', 1, 1, Inf),...
            nla.inputField.Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1),...
            nla.inputField.Number('d_max', "Net-level Cohen's D threshold >", 0, 0.5, 1);};
        end
    end
end