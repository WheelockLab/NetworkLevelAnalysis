classdef NetworkTestsTestCase < matlab.unittest.TestCase

    properties
        root_path        
        network_atlas
        network_test_options
        edge_test_options
        edge_test_result
        tests
    end

    methods (TestClassSetup)
        function loadInputData(testCase)
            import nla.TriMatrix

            testCase.tests = nla.TestPool();
            testCase.tests.edge_test = nla.edge.test.Precalculated();
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

            permutation_p_file = load(strcat(precalculated_path, 'SIM_perm_p.mat'));
            testCase.edge_test_options.precalc_perm_p = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_perm_p.v = permutation_p_file.SIM_perm_p;
            permutation_coefficient_file = load(strcat(precalculated_path, 'SIM_perm_coeff.mat'));
            testCase.edge_test_options.precalc_perm_coeff = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_perm_coeff.v = permutation_coefficient_file.SIM_perm_coeff;

            testCase.edge_test_options.net_atlas = testCase.network_atlas;
            testCase.edge_test_options.prob_max = 0.05;
            testCase.edge_test_options.permute_method = nla.edge.permutationMethods.None();

            testCase.network_test_options = nla.net.genBaseInputs();
            testCase.network_test_options.prob_max = 0.05;
            testCase.network_test_options.behavior_count = 1;
            testCase.network_test_options.d_max = 0.5;
            testCase.network_test_options.prob_plot_method = nla.gfx.ProbPlotMethod.DEFAULT;

            testCase.edge_test_result = testCase.tests.runEdgeTest(testCase.edge_test_options);
        end
    end

    methods (TestClassTeardown)
        function clearData(testCase)
            clear 
        end
    end

    methods (Test)
        function chiSquaredTestTest(testCase)
            import nla.net.test.ChiSquaredTest

            chi_squared_test = ChiSquaredTest();
            load(strcat(testCase.root_path, fullfile('+nla', '+net', 'unittests', 'ChiSquaredTestResult.mat')), 'chi_squared_result');
            test_result = chi_squared_test.run(testCase.network_test_options, testCase.edge_test_result, testCase.network_atlas, false);
            testCase.verifyEqual(test_result.no_permutations.chi2_statistic.v, chi_squared_result);
        end

        function hyperGeometricTestTest(testCase)
            import nla.net.test.HyperGeometricTest

            hypergeometric_test = HyperGeometricTest();
            load(strcat(testCase.root_path, fullfile('+nla', '+net', 'unittests', 'HyperGeometricTestResult.mat')), 'hyper_geo_result');
            test_result = hypergeometric_test.run(testCase.network_test_options, testCase.edge_test_result, testCase.network_atlas, false);
            testCase.verifyEqual(test_result.no_permutations.uncorrected_two_sample_p_value.v, hyper_geo_result);
        end

        function kolmogorovSmirnovTestTest(testCase)
            import nla.net.test.KolmogorovSmirnovTest

            ks_test = KolmogorovSmirnovTest();
            load(strcat(testCase.root_path, fullfile('+nla', '+net', 'unittests', 'KSTestResult.mat')), 'ks_result');
            test_result = ks_test.run(testCase.network_test_options, testCase.edge_test_result, testCase.network_atlas, false);
            testCase.verifyEqual(test_result.no_permutations.ks_statistic.v, ks_result);
        end

        function studentTTestTest(testCase)
            import nla.net.test.StudentTTest

            student_t_test = StudentTTest();
            load(strcat(testCase.root_path, fullfile('+nla', '+net', 'unittests', 'StudentTTestResult.mat')), 'studentt_result');
            test_result = student_t_test.run(testCase.network_test_options, testCase.edge_test_result, testCase.network_atlas, false);
            testCase.verifyEqual(test_result.no_permutations.t_statistic.v, studentt_result);
        end

        function welchTTestTest(testCase)
            import nla.net.test.WelchTTest

            welch_t_test = WelchTTest();
            load(strcat(testCase.root_path, fullfile('+nla', '+net', 'unittests', 'WelchTTestResult.mat')), 'welcht_result');
            test_result = welch_t_test.run(testCase.network_test_options, testCase.edge_test_result, testCase.network_atlas, false);
            testCase.verifyEqual(test_result.no_permutations.t_statistic.v, welcht_result);
        end

        function wilcoxonTestTest(testCase)
            import nla.net.test.WilcoxonTest

            wilcoxon_test = WilcoxonTest();
            load(strcat(testCase.root_path, fullfile('+nla', '+net', 'unittests', 'WilcoxonTestResult.mat')), 'wilconxon_result');
            test_result = wilcoxon_test.run(testCase.network_test_options, testCase.edge_test_result, testCase.network_atlas, false);
            testCase.verifyEqual(test_result.no_permutations.ranksum_statistic.v, wilconxon_result);
        end
    end
end