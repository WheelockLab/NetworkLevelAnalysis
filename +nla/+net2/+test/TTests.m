classdef TTests < handle
    %TTESTs Student's t-test (t-test assuming normal distributions) or 
    % Welch's t-Test (t-test assuming normal distributions with unequal variances)
    properties
        name = "students_t"
    end

    properties (Constant)
        statistics = ["t_statistic", "single_sample_t_statistic"]
    end

    methods 
        function obj = TTests()
        end

        function result = run(obj, test_options, edge_test_results, network_atlas, test_type)
            %RUN runs the Welch's t-test
            %  test_options: The selected values for the test to be run. Formerly input_struct. Options are in nla.net.genBaseInputs
            %  edge_test_results: Non-permuted edge test results. Formerly edge_result
            %  network_atlas: Network atlas for data
            %  test_type: Welch's (welchs) or Student's (students) t-test (default: students)

            import nla.TriMatrix nla.TriMatrixDiag

            if nargin == 2
                test_type = "students";
            elseif nargin == 3 && test_type == "welchs"
                obj.name = "welchs_t";
            end

            number_of_networks = network_atlas.numNets();

            result = nla.net2.result.NetworkTestResult(test_options, number_of_networks, obj.name, obj.statistics);
            result.permutation_results.t_statistic = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            result.permutation_results.single_sample_t_statistic = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);

            % Double for-loop to iterate through trimatrix. Network is the row, network2 the column. Since
            % we only care about the bottom half, second for-loop is 1:network
            for network = 1:number_of_networks
                for network2 = 1:network
                    network_rho = edge_test_results.coeff.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network2).indexes);

                    if test_type == "Welchs" || test_type == "W"
                        [~, p, ~, stats] = ttest2(network_rho, edge_test_results.coeff.v, "Vartype", "unequal");
                    elseif test_type == "Students" || test_type == "S"
                        [~, p, ~, stats] = ttest2(network_rho, edge_test_results.coeff.v);
                    end

                    [~, single_sample_p, ~, single_sample_stats] = ttest(network_rho);

                    result.permutation_results.p_value.set(network, network2, p);
                    result.permutation_results.t_statistic.set(network, network2, stats.tstat);
                    result.permutation_results.single_sample_p_value.set(network, network2, single_sample_p);
                    result.permutation_results.single_sample_t_statistic.set(network, network2, single_sample_stats.tstat);
                end
            end
            
        end
    end
end