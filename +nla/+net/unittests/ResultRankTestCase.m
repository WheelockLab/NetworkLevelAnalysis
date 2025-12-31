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
        rank_results
        ResultRank
        rank
        permuted_edge_results
        permuted_network_results
    end

    properties (Constant)
        number_of_networks = 15
        number_of_network_pairs = 120
        permutations = 25
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
            testCase.edge_test_options.precalc_perm_p.v = testCase.edge_test_options.precalc_perm_p.v(:, 1:25);
            testCase.edge_test_options.precalc_perm_coeff.v = testCase.edge_test_options.precalc_perm_coeff.v(:, 1:25);

            testCase.edge_test_options.net_atlas = testCase.network_atlas;
            testCase.edge_test_options.prob_max = 0.05;
            testCase.edge_test_options.permute_method = nla.edge.permutationMethods.None();

            testCase.network_test_options = nla.net.genBaseInputs();
            testCase.network_test_options.prob_max = 0.05;
            testCase.network_test_options.behavior_count = 1;
            testCase.network_test_options.d_max = 0.5;
            testCase.network_test_options.prob_plot_method = nla.gfx.ProbPlotMethod.DEFAULT;
            testCase.network_test_options.full_connectome = true;
            testCase.network_test_options.within_network_pair = true;
            testCase.network_test_options.no_permutations = true;

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

            rank_results = load(strcat(testCase.root_path, fullfile('+nla', '+net', 'unittests', 'resultRank_results.mat')));
            testCase.rank_results = rank_results.rank_results;
            testCase.ResultRank = nla.net.ResultRank(testCase.permuted_network_results{1}, testCase.number_of_network_pairs);
            testCase.rank = testCase.ResultRank.rank();
        end
    end


    methods (Test)
        function fullConnectomeUncorrectedRankingTest(testCase)
            legacy_results = testCase.rank.full_connectome.legacy_two_sample_p_value.v;
            expected_legacy = testCase.rank_results.full_connectome.legacy_two_sample_p_value.v;

            testCase.verifyEqual(legacy_results, expected_legacy);

            uncorrected_results = testCase.rank.full_connectome.uncorrected_two_sample_p_value.v;
            expected_uncorrected = testCase.rank_results.full_connectome.uncorrected_two_sample_p_value.v;

            testCase.verifyEqual(uncorrected_results, expected_uncorrected);
        end

        function fullConnectomeFreedmanLaneRankingTest(testCase)
            freedman_lane_results = testCase.rank.full_connectome.freedman_lane_two_sample_p_value.v;
            expected_freedman_lane = testCase.rank_results.full_connectome.freedman_lane_two_sample_p_value.v;

            testCase.verifyEqual(freedman_lane_results, expected_freedman_lane);
        end

        function fullConnectomeWestfallYoungRankingTest(testCase)
            westfall_young_results = testCase.rank.full_connectome.westfall_young_two_sample_p_value.v;
            expected_westfall_young = testCase.rank_results.full_connectome.westfall_young_two_sample_p_value.v;

            testCase.verifyEqual(westfall_young_results, expected_westfall_young);
        end

        function withinNetworkPairUncorrectedRankingTest(testCase)
            legacy_results = testCase.rank.within_network_pair.legacy_single_sample_p_value.v;
            expected_legacy = testCase.rank_results.within_network_pair.legacy_single_sample_p_value.v;

            testCase.verifyEqual(legacy_results, expected_legacy);

            uncorrected_results = testCase.rank.within_network_pair.uncorrected_single_sample_p_value.v;
            expected_uncorrected = testCase.rank_results.within_network_pair.uncorrected_single_sample_p_value.v;

            testCase.verifyEqual(uncorrected_results, expected_uncorrected);           
        end

        function withinNetworkPairFreedmanLaneRankingTest(testCase)
            freedman_lane_results = testCase.rank.within_network_pair.freedman_lane_single_sample_p_value.v;
            expected_freedman_lane = testCase.rank_results.within_network_pair.freedman_lane_single_sample_p_value.v;

            testCase.verifyEqual(freedman_lane_results, expected_freedman_lane);
        end

        function withinNetworkPairWestfallYoungRankingTest(testCase)
            westfall_young_results = testCase.rank.within_network_pair.westfall_young_single_sample_p_value.v;
            expected_westfall_young = testCase.rank_results.within_network_pair.westfall_young_single_sample_p_value.v;

            testCase.verifyEqual(westfall_young_results, expected_westfall_young);
        end
    end
end