classdef NetworkTestLegacyTestCase < matlab.unittest.TestCase

    properties
        tests
        root_path
        network_atlas
        edge_test_options
        edge_test_result
        network_test_options
        network_results
        legacy_results
        permutation_edge_results
        nonpermuted_network_results
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
            testCase.tests.net_tests = {...
                nla.net.test.ChiSquaredTest(),...
                nla.net.test.HyperGeometricTest(),...
                nla.net.test.KolmogorovSmirnovTest(),...
                nla.net.test.WelchTTest(),...
                nla.net.test.WilcoxonTest()...    
            };
            testCase.root_path = nla.findRootPath();
            
            % Load up a network atlas
            net_atlas_path = strcat(testCase.root_path, fullfile('support_files', 'Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat'));
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
            testCase.network_test_options.within_network_pair = true;
            testCase.network_test_options.no_permutations = true;

            % testCase.permutation_edge_results = testCase.tests.runEdgeTestPerm(testCase.edge_test_options, testCase.permutations);
            testCase.nonpermuted_network_results = testCase.tests.runNetTests(testCase.network_test_options, testCase.edge_test_result, testCase.network_atlas, false);

            testCase.network_results = testCase.tests.runPerm(...
                testCase.edge_test_options,...
                testCase.network_test_options,...
                testCase.network_atlas,...
                testCase.edge_test_result,...
                testCase.nonpermuted_network_results,...
                testCase.permutations...
            );
            testCase.legacy_results = load(strcat(testCase.root_path, fullfile('+nla', '+net', 'unittests', 'legacy_pearson_results.mat')));
        end
    end

    methods (Test)
        function chiSquaredTestCase(testCase)
            legacy_result = testCase.legacy_results.noPerm;
            for test = 1:numel(testCase.network_results.permutation_network_test_results)
                if testCase.network_results.permutation_network_test_results(test).name == "chi_squared"
                    result = endtestCase.network_results.permutation_network_test_results(test);
                end
            end
            testCase.verifyEqual(result.no_permutations.p_value, legacy_result)
        end
    end
end