classdef NetworkResultPlotParameterTestCase < matlab.unittest.TestCase

    properties
        root_path
        network_atlas
        edge_test_options
        network_test_options
        edge_test_result
        network_test_result
        permutation_results
        tests
    end

    methods (TestMethodSetup)
        function loadInputData(testCase)
            import nla.TriMatrix

            testCase.tests = nla.TestPool();
            testCase.tests.edge_test = nla.edge.test.Precalculated();
            testCase.tests.net_tests = {nla.net.test.StudentTTest()};
            testCase.root_path = nla.findRootPath();

            % Load up a network atlas
            net_atlas_path = strcat(testCase.root_path, fullfile('support_files', 'Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat'));
            testCase.network_atlas = nla.NetworkAtlas(net_atlas_path);

            % Load in some edge test results
            testCase.edge_test_options = struct();
            testCase.edge_test_options.coeff_max = 2;
            testCase.edge_test_options.coeff_min = -2;
            testCase.edge_test_options.iteration = 0;

            precalculated_path = strcat(testCase.root_path, fullfile('examples', 'precalculated/'));
            
            observed_p_file = load(strcat(precalculated_path, 'SIM_obs_p.mat'));
            testCase.edge_test_options.precalc_obs_p = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_obs_p.v = observed_p_file.SIM_obs_p;
            observed_coefficients_file = load(strcat(precalculated_path, 'SIM_obs_coeff.mat'));
            testCase.edge_test_options.precalc_obs_coeff = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_obs_coeff.v = observed_coefficients_file.SIM_obs_coeff;

            permutation_p_file = load(strcat(precalculated_path, 'SIM_perm_p.mat'));
            testCase.edge_test_options.precalc_perm_p = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_perm_p.v = permutation_p_file.SIM_perm_p;
            permutation_coefficient_file = load(strcat(precalculated_path, 'SIM_perm_coeff.mat'));
            testCase.edge_test_options.precalc_perm_coeff = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_perm_coeff.v = permutation_coefficient_file.SIM_perm_coeff;
            % For unit tests, we're only going to use 10 permutations so they don't take forever
            testCase.edge_test_options.precalc_perm_p.v = testCase.edge_test_options.precalc_perm_p.v(:, 1:10);
            testCase.edge_test_options.precalc_perm_coeff.v = testCase.edge_test_options.precalc_perm_coeff.v(:, 1:10);

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

            permutations = size(testCase.edge_test_options.precalc_perm_p.v, 2);

            testCase.edge_test_result = testCase.tests.runEdgeTest(testCase.edge_test_options);
            testCase.network_test_result = testCase.tests.runNetTests(testCase.network_test_options,...
                testCase.edge_test_result, testCase.network_atlas, false);
            testCase.edge_test_options.iteration = 1;
            testCase.permutation_results = testCase.tests.runPerm(testCase.edge_test_options, testCase.network_test_options,...
                testCase.network_atlas, testCase.edge_test_result, testCase.network_test_result,...
                permutations);
        end
    end

    methods (TestMethodTeardown)
        function clearData(testCase)
            clear 
        end
    end

    methods (Test)
        function plotProbabilityParametersDefaultPlottingTest(testCase)
            import nla.net.result.NetworkResultPlotParameter nla.TriMatrix nla.TriMatrixDiag

            permutation_result = testCase.permutation_results.permutation_network_test_results{1};
            plot_parameters = NetworkResultPlotParameter(permutation_result, testCase.network_atlas,...
                testCase.network_test_options);

            probability_parameters = plot_parameters.plotProbabilityParameters(testCase.edge_test_options,...
                testCase.edge_test_result, 'full_connectome', 'p_value', 'Title', nla.net.mcc.Bonferroni(),...
                false);
            
            expected_p_value_max = testCase.network_test_options.prob_max / testCase.network_atlas.numNetPairs();
            expected_plot = nla.TriMatrix(plot_parameters.number_of_networks, "double", nla.TriMatrixDiag.KEEP_DIAGONAL);
            expected_plot.v = permutation_result.full_connectome.p_value.v .*...
                (plot_parameters.default_discrete_colors / (plot_parameters.default_discrete_colors + 1));
            expected_significance_type = nla.gfx.SigType.DECREASING;
            expected_color_map = [flip(parula(plot_parameters.default_discrete_colors)); [1 1 1]];

            testCase.verifyEqual(expected_p_value_max, probability_parameters.p_value_plot_max);
            testCase.verifyEqual(expected_plot.v, probability_parameters.statistic_plot_matrix.v);
            testCase.verifyEqual(expected_significance_type, probability_parameters.significance_type);
            testCase.verifyEqual(expected_color_map, probability_parameters.color_map);
        end

        function plotProbabilityParametersLogPlottingTest(testCase)
            import nla.net.result.NetworkResultPlotParameter
            
            permutation_result = testCase.permutation_results.permutation_network_test_results{1};
            testCase.network_test_options.prob_plot_method = nla.gfx.ProbPlotMethod.LOG;

            plot_parameters = NetworkResultPlotParameter(permutation_result, testCase.network_atlas,...
                testCase.network_test_options);

            probability_parameters = plot_parameters.plotProbabilityParameters(testCase.edge_test_options,...
                testCase.edge_test_result, 'full_connectome', 'p_value', 'Title', nla.net.mcc.Bonferroni(),...
                false);

            expected_p_value_max = testCase.network_test_options.prob_max / testCase.network_atlas.numNetPairs();
            expected_plot = nla.TriMatrix(plot_parameters.number_of_networks, "double", nla.TriMatrixDiag.KEEP_DIAGONAL);
            expected_plot.v = permutation_result.full_connectome.p_value.v .*...
                (plot_parameters.default_discrete_colors / (plot_parameters.default_discrete_colors + 1));
            expected_significance_type = nla.gfx.SigType.DECREASING;

            expected_log_minimum = log10(min(nonzeros(permutation_result.full_connectome.p_value.v)));
            expected_log_minimum = max([-40, expected_log_minimum]);
            color_map_base = parula(plot_parameters.default_discrete_colors);
            expected_color_map = flip(color_map_base(ceil(logspace(expected_log_minimum, 0, plot_parameters.default_discrete_colors) .*...
                plot_parameters.default_discrete_colors), :));
            expected_color_map = [expected_color_map; [1 1 1]];

            testCase.verifyEqual(expected_p_value_max, probability_parameters.p_value_plot_max);
            testCase.verifyEqual(expected_plot.v, probability_parameters.statistic_plot_matrix.v);
            testCase.verifyEqual(expected_significance_type, probability_parameters.significance_type);
            testCase.verifyEqual(expected_color_map, probability_parameters.color_map);
        end

        function plotProbabilityParametersNegLogTest(testCase)
            import nla.net.result.NetworkResultPlotParameter
            
            permutation_result = testCase.permutation_results.permutation_network_test_results{1};
            testCase.network_test_options.prob_plot_method = nla.gfx.ProbPlotMethod.NEG_LOG_10;

            plot_parameters = NetworkResultPlotParameter(permutation_result, testCase.network_atlas,...
                testCase.network_test_options);

            probability_parameters = plot_parameters.plotProbabilityParameters(testCase.edge_test_options,...
                testCase.edge_test_result, 'full_connectome', 'p_value', 'Title', nla.net.mcc.Bonferroni(),...
                false);

            expected_p_value_max = 2;
            expected_plot = nla.TriMatrix(plot_parameters.number_of_networks, "double", nla.TriMatrixDiag.KEEP_DIAGONAL);
            expected_plot.v = -log10(permutation_result.full_connectome.p_value.v);
            expected_significance_type = nla.gfx.SigType.INCREASING;
            expected_color_map = parula(plot_parameters.default_discrete_colors);

            testCase.verifyEqual(expected_p_value_max, probability_parameters.p_value_plot_max);
            testCase.verifyEqual(expected_plot.v, probability_parameters.statistic_plot_matrix.v);
            testCase.verifyEqual(expected_significance_type, probability_parameters.significance_type);
            testCase.verifyEqual(expected_color_map, probability_parameters.color_map);
        end
    end
end