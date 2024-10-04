classdef TestPoolTest < matlab.unittest.TestCase

    properties
        root_path
        network_atlas
        edge_test_options
        network_test_options
        edge_results_permuted
        network_results_nonpermuted
        network_results_permuted
        ranked_network_results
        tests
    end

    properties (Constant)
        number_of_networks = 15
        number_of_network_pairs = 120
        permutations = 20
    end

    methods (TestClassSetup)
        function loadTestData(testCase)
            testCase.variables = {};

            load(fullfile('nla', 'tests', 'inputStruct'), 'input_struct');
            testCase.variables.input_struct = input_struct;
            load(fullfile('nla', 'tests', 'edgeResultsPermuted'), 'edge_results_perm');
            testCase.variables.edge_results_perm = edge_results_perm;
            load(fullfile('nla', 'tests', 'networkInputStruct'), 'net_input_struct');
            testCase.variables.net_input_struct = net_input_struct;
            load(fullfile('nla', 'tests', 'networkAtlas'), 'net_atlas');
            testCase.variables.net_atlas = net_atlas;
        end
    end

    methods (TestClassTeardown)
        function clearTestData(testCase)
            clear
        end
    end

    methods (Test)
        function permutationEdgeTest(testCase)
            import nla.TestPool
            
            nonpermuted_edge_results = testCase.tests.runEdgeTest(testCase.edge_test_options);
            permuted_edge_results = testCase.tests.runEdgeTestPerm(testCase.edge_test_options, testCase.permutations, 1);
            testCase.verifyEqual(permuted_edge_results, testCase.edge_results_permuted);
        end
    end
end