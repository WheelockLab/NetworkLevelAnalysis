classdef ResultRankTestCase < matlab.unittest.TestCase
    properties
        root_path
        network_atlas
        edge_test_options
        network_test_options
        edge_test_result
        network_test_result
        permutation_results
        tests
        ranking
        permuted_edge_results
        permuted_network_results
    end

    properties (Constant)
        number_of_networks = 15
        number_of_network_pairs = 120
        permutations = 9
    end

    methods (TestClassSetup)
        function loadInputData(testCase)
            import nla.TriMatrix

            testCase.tests = nla.TestPool();
            testCase.tests.edge_test = nla.edge.test.Precalculated();
            testCase.tests.net_tests = {nla.net.test.StudentTTest()};
            testCase.root_path = nla.findRootPath();

            % Load up a network atlas
            net_atlas_path = strcat(testCase.root_path, fullfile('support_files',...
                'Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat'));
            testCase.network_atlas = nla.NetworkAtlas(net_atlas_path);

            % Load in some edge test results
            testCase.edge_test_options = struct();
            testCase.edge_test_options.coeff_max = 2;
            testCase.edge_test_options.coeff_min = -2;

            precalculated_path = strcat(testCase.root_path, fullfile('examples', 'precalculated/'));
            
            observed_p_file = load(strcat(precalculated_path, 'SIM_obs_p.mat'));
            testCase.edge_test_options.precalc_obs_p = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_obs_p.v = observed_p_file.SIM_obs_p;
            observed_coefficients_file = load(strcat(precalculated_path, 'SIM_obs_coeff.mat'));
            testCase.edge_test_options.precalc_obs_coeff = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_obs_coeff.v = observed_coefficients_file.SIM_obs_coeff;
            testCase.edge_test_options.net_atlas = testCase.network_atlas; % These naming schemes are the worst
            testCase.edge_test_options.prob_max = 0.05;
            testCase.edge_test_options.iteration = 0;

            testCase.edge_test_result = testCase.tests.edge_test.run(testCase.edge_test_options);
            
            permutation_p_file = load(strcat(precalculated_path, 'SIM_perm_p.mat'));
            testCase.edge_test_options.precalc_perm_p = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_perm_p.v = permutation_p_file.SIM_perm_p;
            permutation_coefficient_file = load(strcat(precalculated_path, 'SIM_perm_coeff.mat'));
            testCase.edge_test_options.precalc_perm_coeff = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_perm_coeff.v = permutation_coefficient_file.SIM_perm_coeff;

            % For unit tests, we're only going to use 10 permutations so they don't take forever
            testCase.edge_test_options.precalc_perm_p.v = testCase.edge_test_options.precalc_perm_p.v(:, 1:9);
            testCase.edge_test_options.precalc_perm_coeff.v = testCase.edge_test_options.precalc_perm_coeff.v(:, 1:9);

            testCase.edge_test_options.net_atlas = testCase.network_atlas;
            testCase.edge_test_options.prob_max = 0.05;
            testCase.edge_test_options.permute_method = nla.edge.permutationMethods.None();

            testCase.network_test_options = nla.net.genBaseInputs();
            testCase.network_test_options.prob_max = 0.05;
            testCase.network_test_options.behavior_count = 1;
            testCase.network_test_options.d_max = 0.5;
            testCase.network_test_options.prob_plot_method = nla.gfx.ProbPlotMethod.DEFAULT;
            testCase.network_test_options.full_connectome = true;
            testCase.network_test_options.within_net_pair = true;
            testCase.network_test_options.nonpermuted = true;

            % Basically have to do everything in the TestPool except run the ranking. So, that's what all this is, everything
            % in TestPool.runPerm up until ranking. Luckily, we're only doing one network test
            testCase.edge_test_result = testCase.tests.runEdgeTest(testCase.edge_test_options);
            testCase.network_test_result = testCase.tests.runNetTests(testCase.network_test_options,...
                testCase.edge_test_result, testCase.network_atlas, false);
            testCase.permuted_edge_results = testCase.tests.runEdgeTestPerm(testCase.edge_test_options, testCase.permutations);
            testCase.permuted_network_results = testCase.tests.runNetTestsPerm(testCase.network_test_options,...
                testCase.network_atlas, testCase.permuted_edge_results);

            cohen_d = nla.net.CohenDTest();
            % Here's where the for-loop is in TestPool.runPerm. Since they are for only 1 test, we can do without the loop
            testCase.permuted_network_results{1} = cohen_d.run(testCase.edge_test_result, testCase.network_atlas,...
                testCase.permuted_network_results{1});
            testCase.permuted_network_results{1}.no_permutations = testCase.network_test_result{1}.no_permutations;

            testCase.ranking = load(strcat(testCase.root_path, fullfile('+nla', '+net', 'unittests', 'resultRank_results.mat')));
            testCase.ranking = testCase.ranking.ranking;
        end
    end


    methods (Test)
        function fullConnectomeRankTest(testCase)
            result_ranker = nla.net.ResultRank(testCase.network_test_result{1}, testCase.permuted_network_results{1},...
                testCase.number_of_network_pairs);
            ranking = testCase.permuted_network_results{1}.copy(); 
            ranking = result_ranker.experimentWideRank(ranking, testCase.permuted_network_results{1}.ranking_statistic);

            testCase.verifyEqual(ranking.full_connectome.p_value.v, testCase.ranking.full_connectome.p_value.v);
        end

        function networkPairTest(testCase)
           result_ranker = nla.net.ResultRank(testCase.network_test_result{1}, testCase.permuted_network_results{1},...
               testCase.number_of_network_pairs);
           ranking = testCase.permuted_network_results{1}.copy();
           ranking = result_ranker.networkPairRank(ranking, testCase.permuted_network_results{1}.ranking_statistic);
           
           testCase.verifyEqual(ranking.within_network_pair.p_value.v, testCase.ranking.within_network_pair.p_value.v);
        end
    end
end