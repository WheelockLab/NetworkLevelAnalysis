classdef CohenDTest < handle
    %COHENDTEST Cohen's D Test for network tests
    % This Cohen's D test is run for all of the tests
    % Input:
    %   edge_test_results: Results from the edge tests
    %   network_atlas: Network Atlas
    %   result_object: This is a NetworkTestResult object. This needs to be passed in, and then it will be returned.

    properties (Constant)
        name = "Cohen's D Test"
    end

    methods
        function obj = CohenDTest
        end

        function result_object = run(obj, edge_test_results, network_atlas, result_object)
            import nla.TriMatrix nla.TriMatrixDiag

            number_of_networks = network_atlas.numNets();

            for row = 1:number_of_networks
                for column = 1:row

                    network_rho = edge_test_results.coeff.get(network_atlas.nets(row).indexes,...
                        network_atlas.nets(column).indexes);
                    
                    single_sample_d = abs(mean(network_rho)) / std(network_rho);
                    d = abs((mean(network_rho) - mean(edge_test_results.coeff.v)) / sqrt(((std(network_rho).^2)) +...
                        (std(edge_test_results.coeff.v).^2)));
                    
                    result_object.no_permutations.d.set(row, column, single_sample_d);
                    if isprop(result_object, "full_connectome") && isequal(result_object.full_connectome, true)
                        result_object.full_connectome.d.set(row, column, d);
                    end
                    if isprop(result_object, "within_network_pair") && isequal(result_object.within_network_pair, true)
                        result_object.within_network_pair.d.set(row, column, single_sample_d);
                    end
                end
            end
        end
    end
end