classdef CohenDTest < handle
    %COHENDTEST Cohen's D Test for network tests

    properties (Constant)
        name = "Cohen's D Test"
    end

    methods
        function obj = CohenDTest
        end

        function result = run(obj, edge_test_results, network_atlas)
            import nla.TriMatrix nla.TriMatrixDiag

            number_of_networks = network_atlas.numNets();

            result = struct();
            result.d_statistic = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);

            for network = 1:number_of_networks
                for network2 = 1:network
                    network_rho = edge_test_results.coeff.get(network_atlas.nets(network).indexes,...
                        network_atlas.nets(network).indexes);
                    all_data_std_denominator = numel(network_rho) + numel(edge_test_results.coeff.v) - 2;
                    all_data_std_numerator = ((numel(network_rho) - 1) .* std(network_rho) .^ 2) +...
                        ((numel(edge_test_results.coeff.v) - 1) .* std(edge_test_results.coeff.v) .^ 2);
                    all_data_std = sqrt(all_data_std_numerator / all_data_std_denominator);
                    d = abs((mean(network_rho)) - mean(edge_test_results.coeff.v)) / all_data_std;
                    result.d_statistic.set(network, network2, d);
                end
            end
        end
    end
end