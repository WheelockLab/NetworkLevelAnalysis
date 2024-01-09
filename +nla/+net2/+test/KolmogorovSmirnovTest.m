classdef KolmogorovSmirnovTest < handle
    %KOLMOGOROVSMIRNOVTEST Kolmogorov-Smirnov test
    properties (Constant)
        name = "kolmogorov_smirnov"
        statistics = ["ks_statistic", "single_sample_ks_statistic"]
    end

    methods
        function obj = KolmogorovSmirnovTest()
        end

        function result = run(obj, edge_test_results, network_atlas)            
            %RUN runs the Kolmogorov-Smirnov goodness of fit test
            %  edge_test_results: Non-permuted edge test results. Formerly edge_result
            %  network_atlas: Network atlas for data
           import nla.TriMatrix nla.TriMatrixDiag
           
           number_of_networks = network_atlas.numNets();

           result = nla.net2.result.NetworkTestResult(number_of_networks, obj.name, obj.statistics);
           result.test_statistics.(obj.name).ks_statistic = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
           result.test_statistics.(obj.name).single_sample_ks_statistic = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);

            % Double for-loop to iterate through trimatrix. Network is the row, network2 the column. Since
            % we only care about the bottom half, second for-loop is 1:network
            for network = 1:number_of_networks
                for network2 = 1:network
                    network_rho = edge_test_results.coeff.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network2).indexes);

                    [~, p, ks] = kstest2(network_rho, edge_test_results.coeff.v);
                    result.p_value.set(network, network2, p);
                    result.test_statistics.(obj.name).ks_statistic.set(network, network2, ks);

                    [~, single_sample_p, single_sample_ks] = kstest(network_rho);
                    result.single_sample_p_value.set(network, network2, single_sample_p);
                    result.test_statistics.(obj.name).single_sample_ks_statistic.set(network_network2, single_sample_ks);
                end
            end
    
        end
    end
end