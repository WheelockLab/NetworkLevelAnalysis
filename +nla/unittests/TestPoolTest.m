classdef TestPoolTest < matlab.unittest.TestCase

    properties
<<<<<<< HEAD
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
=======
        variables
>>>>>>> Fix up the whole testpool testing. I have no clue how it was even working before. Really, need to get my head checked
    end

    methods (TestClassSetup)
        function loadTestData(testCase)
<<<<<<< HEAD
            import nla.TriMatrix

            testCase.root_path = nla.findRootPath();
            testCase.tests = nla.TestPool();
            testCase.tests.net_tests = nla.genTests('net.test');

            network_atlas_path = strcat(testCase.root_path, fullfile("support_files", "Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat"));
            testCase.network_atlas = nla.NetworkAtlas(network_atlas_path);

            functional_connectivity_path = strcat(testCase.root_path, fullfile("examples/fc_and_behavior/sample_func_conn.mat"));
            functional_connectivity_struct = load(functional_connectivity_path);
            functional_connectivity_unordered = double(functional_connectivity_struct.fc);
            if all(abs(functional_connectivity_unordered(:)) <= 1)
                functional_connectivity_unordered = nla.fisherR2Z(functional_connectivity_unordered);
            end
            testCase.edge_test_options.func_conn = TriMatrix(functional_connectivity_unordered(testCase.network_atlas.ROI_order, testCase.network_atlas.ROI_order, :));

            testCase.edge_test_options.prob_max = 0.05;
            testCase.edge_test_options.iteration = 0;
            testCase.edge_test_options.net_atlas = testCase.network_atlas;
            testCase.edge_test_options.permute_method = nla.edge.permutationMethods.BehaviorVec();

            behavior_path = strcat(testCase.root_path, "examples/fc_and_behavior/sample_behavior.mat");
            behavior_struct = load(behavior_path);
            behavior = behavior_struct.Bx;
            testCase.edge_test_options.behavior = behavior(:, 10).Variables;

            testCase.network_test_options = nla.net.genBaseInputs();
            testCase.network_test_options.prob_max = 0.05;
            testCase.network_test_options.behavior_count = 1;
            testCase.network_test_options.d_max = 0.5;
            testCase.network_test_options.prob_plot_method = nla.gfx.ProbPlotMethod.DEFAULT;
            testCase.network_test_options.full_connectome = true;
            testCase.network_test_options.within_network_pair = true;
            testCase.network_test_options.no_permutations = true;

            testCase.edge_results_permuted = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "edgeResultsPermuted")), "edge_results_permuted");
            testCase.edge_results_permuted = testCase.edge_results_permuted.edge_results_permuted;
            testCase.network_results_nonpermuted = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "networkResultsNonPermuted")), "nonpermuted_network_results");
            testCase.network_results_permuted = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "networkResultsPermuted")), "permuted_network_results");
            testCase.network_results_permuted = testCase.network_results_permuted.permuted_network_results;
            testCase.ranked_network_results = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "networkResultsRanked")), "ranked_network_results");
            testCase.ranked_network_results = testCase.ranked_network_results.ranked_network_results;
=======
            testCase.variables = {};

            load(fullfile('+nla', 'unittests', 'inputStruct.mat'), 'input_struct');
            testCase.variables.input_struct = input_struct;
            load(fullfile('+nla', 'unittests', 'edgeResultsPermuted.mat'), 'saved_permuted_edge_test_results');
            testCase.variables.edge_results_perm = saved_permuted_edge_test_results;
            load(fullfile('+nla', 'unittests', 'networkInputStruct.mat'), 'net_input_struct');
            testCase.variables.net_input_struct = net_input_struct;
            load(fullfile('+nla', 'unittests', 'networkResultsNonPermuted.mat'), 'nonpermuted_network_level_results');
            testCase.variables.net_results_nonperm = nonpermuted_network_level_results;
            load(fullfile('+nla', 'unittests', 'networkResultsPermuted.mat'), 'permuted_network_level_results');
            testCase.variables.net_results_perm = permuted_network_level_results;
            load(fullfile('+nla', 'unittests', 'networkAtlas.mat'), 'network_atlas');
            testCase.variables.network_atlas = network_atlas;
            load(fullfile("+nla", "unittests", "rankedNetworkResults.mat"), "ranked_network_results");
            testCase.variables.ranked_network_results = ranked_network_results;
>>>>>>> Fix up the whole testpool testing. I have no clue how it was even working before. Really, need to get my head checked
        end
    end

    methods (TestClassTeardown)
        function clearTestData(testCase)
<<<<<<< HEAD
            clear
=======
            clear testCase.variables
>>>>>>> Fix up the whole testpool testing. I have no clue how it was even working before. Really, need to get my head checked
        end
    end

    methods (Test)
        function permutationEdgeTest(testCase)
            import nla.TestPool
            
<<<<<<< HEAD
            nonpermuted_edge_results = testCase.tests.runEdgeTest(testCase.edge_test_options);
            permuted_edge_results = testCase.tests.runEdgeTestPerm(testCase.edge_test_options, testCase.permutations, 1);
            testCase.verifyEqual(permuted_edge_results, testCase.edge_results_permuted);
=======
            test_pool = TestPool();
            permuted_edge_results = test_pool.runEdgeTestPerm(testCase.variables.input_struct, 20, 1);
            testCase.verifyEqual(permuted_edge_results, testCase.variables.edge_results_perm);
>>>>>>> Fix up the whole testpool testing. I have no clue how it was even working before. Really, need to get my head checked
        end

        function permutationNetworkTests(testCase)
            import nla.TestPool

<<<<<<< HEAD
            nonpermuted_edge_results = testCase.tests.runEdgeTest(testCase.edge_test_options);
            nonpermuted_network_results = testCase.tests.runNetTests(testCase.network_test_options, nonpermuted_edge_results, testCase.network_atlas, false);
            network_level_results = testCase.tests.runNetTestsPerm(testCase.network_test_options, testCase.network_atlas, testCase.edge_results_permuted);
            % We could go with the assumption that the two are in the same order, but I'd rather be safe
            for result_index1 = 1:numel(network_level_results)
                for result_index2 = 1:numel(testCase.network_results_nonpermuted)
                    if network_level_results{result_index1}.test_name == testCase.network_results_permuted{result_index2}.test_name
                        network_level_results{result_index1}.no_permutations = testCase.network_results_permuted{result_index2}.no_permutations;
=======
            test_pool = TestPool();
            test_pool.net_tests = nla.genTests('net.test');
            network_level_results = test_pool.runNetTestsPerm(testCase.variables.net_input_struct, testCase.variables.network_atlas, testCase.variables.edge_results_perm);
            % We could go with the assumption that the two are in the same order, but I'd rather be safe
            for result_index1 = 1:numel(network_level_results)
                for result_index2 = 1:numel(testCase.variables.net_results_nonperm)
                    if network_level_results{result_index1}.test_name == testCase.variables.net_results_nonperm{result_index2}.test_name
                        network_level_results{result_index1}.no_permutations = testCase.variables.net_results_nonperm{result_index2}.no_permutations;
>>>>>>> Fix up the whole testpool testing. I have no clue how it was even working before. Really, need to get my head checked
                        break
                    end
                end
            end
<<<<<<< HEAD
            ranked_network_results = testCase.tests.rankResults(testCase.network_test_options, network_level_results, testCase.network_atlas.numNetPairs());
            % Here's the loop and the actual verification
            for result_index1 = 1:numel(network_level_results)
                for result_index2 = 1:numel(testCase.network_results_permuted)
                    if network_level_results{result_index1}.test_name == testCase.network_results_permuted{result_index2}.test_name
                        % Verify that the whole result object is the same. 
                        testCase.verifyEqual(ranked_network_results{result_index1}, testCase.ranked_network_results{result_index2});
=======
            ranked_network_results = test_pool.rankResults(testCase.variables.net_input_struct, network_level_results, testCase.variables.network_atlas.numNetPairs());
            % Here's the loop and the actual verification
            for result_index1 = 1:numel(network_level_results)
                for result_index2 = 1:numel(testCase.variables.net_results_perm)
                    if network_level_results{result_index1}.test_name == testCase.variables.net_results_perm{result_index2}.test_name
                        % Verify that the whole result object is the same. 
                        testCase.verifyEqual(ranked_network_results{result_index1}, testCase.variables.ranked_network_results{result_index2});
>>>>>>> Fix up the whole testpool testing. I have no clue how it was even working before. Really, need to get my head checked
                        break
                    end
                end
            end
        end
    end
end