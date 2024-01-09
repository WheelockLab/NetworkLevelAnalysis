classdef WilcoxonTest < handle
    %WILCOXON Wilcoxon rank sum test
    properties (Constant)
        name = "wilcoxon"
        statistics = ["ranksum_statistic", "single_sample_ranksum_statistic", "z_statistic"]
    end

    methods
        function obj = WilcoxonTest()
        end

        function result = run(obj, test_options, edge_test_results, network_atlas)
            %RUN runs the Wilcoxon rank-sum test
            %  test_options: The selected values for the test to be run. Formerly input_struct. Options are in nla.net.genBaseInputs
            %  edge_test_results: Non-permuted edge test results. Formerly edge_result
            %  network_atlas: Network atlas for data

            import nla.TriMatrix nla.TriMatrixDiag

            number_of_networks = network_atlas.numNets();

            result = nla.net2.result.NetworkTestResult(test_options, number_of_networks, obj.name, obj.statistics);
            result.test_statistics.(obj.name).ranksum_statistic = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            result.test_statistics.(obj.name).z_statistic = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
            result.test_statistics.(obj.name).single_sample_ranksum_statistic = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);

            % Double for-loop to iterate through trimatrix. Network is the row, network2 the column. Since
            % we only care about the bottom half, second for-loop is 1:network
            for network = 1:number_of_networks
                for network2 = 1:network
                    network_rho = edge_test_results.coeff.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network2).indexes);

                    [p, ~, stats] = ranksum(network_rho, edge_test_results.coeff.v);
                    result.p_value.set(network, network2, p);
                    result.test_statistics.(obj.name).ranksum_statistic.set(network, network2, stats.ranksum);
                    result.test_statistics.(obj.name).z_statistic.set(network, network2, stats.zval);
                    
                    [single_sample_p, ~, single_sample_stats] = signrank(network_rho);
                    result.single_sample_p_value.set(network, network2, single_sample_p);
                    result.test_statistics.(obj.name).single_sample_ranksum_statistic(network, network2, single_sample_ranksum_statistic);
                end
            end
        end
    end
end