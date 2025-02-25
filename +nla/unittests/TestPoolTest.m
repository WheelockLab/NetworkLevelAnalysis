classdef TestPoolTest < matlab.unittest.TestCase

    properties
        edge_test_options
        network_test_options
        tests
        root_path
    end

    properties (Constant)
        permutations = 20
    end

    methods (TestClassSetup)
        function loadTestData(testCase)
            import nla.TriMatrix

            testCase.root_path = nla.findRootPath();
            testCase.tests = nla.TestPool();

            % load functional connectivity
            fc_path = strcat(testCase.root_path, fullfile("examples", "fc_and_behavior", "sample_func_conn.mat"));
            fc_unordered = load(fc_path);
            fc_unordered = double(fc_unordered.fc);
            if all(abs(fc_unordered(:)) <= 1)
                fc_unordered = nla.fisherR2Z(fc_unordered);
            end

            % load network atlas
            network_atlas_path = strcat(testCase.root_path, fullfile("support_files", "Wheelock_2020_CerebralCortex_17nets_300ROI_on_MNI.mat"));
            network_atlas_loaded = load(network_atlas_path);
            network_to_remove = ["US"];
            [network_atlas] = nla.removeNetworks(network_atlas_loaded, network_to_remove, "Wheelock_2020_CerebralCortex_16nets_288ROI_on_MNI");
            network_atlas = nla.NetworkAtlas(network_atlas);

            % load behavior file
            behavior_path = strcat(testCase.root_path, fullfile("examples", "fc_and_behavior", "sample_behavior.mat"));
            behavior = load(behavior_path);
            behavior = behavior.Bx;

            testCase.edge_test_options = struct();
            testCase.edge_test_options.net_atlas = network_atlas;
            testCase.edge_test_options.func_conn = TriMatrix(fc_unordered(network_atlas.ROI_order, network_atlas.ROI_order, :));
            testCase.edge_test_options.behavior = behavior(:, 10).Variables;
            testCase.edge_test_options.prob_max = 0.05;
            testCase.edge_test_options.permute_method = nla.edge.permutationMethods.BehaviorVec();
            testCase.edge_test_options.iteration = 0;

            
            testCase.network_test_options = nla.net.genBaseInputs();
            testCase.network_test_options.prob_max = 0.05;
            testCase.network_test_options.behavior_count = 1;
            testCase.network_test_options.d_max = 0.5;
            testCase.network_test_options.prob_plot_method = nla.gfx.ProbPlotMethod.DEFAULT;
            testCase.network_test_options.full_connectome = true;
            testCase.network_test_options.no_permutations = true;
            testCase.network_test_options.within_network_pair = true;
        end
    end

    methods (TestClassTeardown)
        function clearTestData(testCase)
            clear
        end
    end

    methods (Test)
        function spearmanEdgeTest(testCase)
            testCase.tests.edge_test = nla.edge.test.Spearman();
            edge_result = testCase.tests.runEdgeTestPerm(testCase.edge_test_options, testCase.permutations, 0);

            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "spearman_result.mat")));
            property_names = properties(edge_result);
            for prop_name = property_names
                testCase.verifyEqual(expected_result.edge_result.(prop_name{1}), edge_result.(prop_name{1}));
            end
        end

        function pearsonEdgeTest(testCase)
            testCase.tests.edge_test = nla.edge.test.Pearson();
            edge_result = testCase.tests.runEdgeTestPerm(testCase.edge_test_options, testCase.permutations, 0);

            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "pearson_result.mat")));
            testCase.verifyEqual(expected_result.edge_result, edge_result);
        end

        function kendallBTest(testCase)
            testCase.tests.edge_test = nla.edge.test.KendallB();
            edge_result = testCase.tests.runEdgeTestPerm(testCase.edge_test_options, testCase.permutations, 0);

            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "kendallb_result.mat")));
            testCase.verifyEqual(expected_result.edge_result, edge_result);
        end

        function spearmanEstimatorTest(testCase)
            testCase.tests.edge_test = nla.edge.test.SpearmanEstimator();
            edge_result = testCase.tests.runEdgeTestPerm(testCase.edge_test_options, testCase.permutations, 0);

            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "spearman_estimator_result.mat")));
            testCase.verifyEqual(expected_result.edge_result, edge_result);
        end
        
        function chiSquaredTest(testCase)
            edge_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "pearson_result.mat")));
            testCase.tests.net_tests = {nla.net.test.ChiSquaredTest()};
            network_result = testCase.tests.runNetTestsPerm(testCase.network_test_options, testCase.edge_test_options.net_atlas, edge_result.edge_result);

            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "chi_squared_result.mat")));
            testCase.verifyEqual(expected_result.network_result, network_result{1});
        end

        function hyperGeometricTest(testCase)
            edge_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "pearson_result.mat")));
            testCase.tests.net_tests = {nla.net.test.HyperGeometricTest()};
            network_result = testCase.tests.runNetTestsPerm(testCase.network_test_options, testCase.edge_test_options.net_atlas, edge_result.edge_result);
            
            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "hypergeometric_result.mat")));
            testCase.verifyEqual(expected_result.network_result, network_result{1});
        end

        function kolmogorovSmirnovTest(testCase)
            edge_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "pearson_result.mat")));
            testCase.tests.net_tests = {nla.net.test.KolmogorovSmirnovTest()};
            network_result = testCase.tests.runNetTestsPerm(testCase.network_test_options, testCase.edge_test_options.net_atlas, edge_result.edge_result);
            
            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "kolmogorov_smirnov_result.mat")));
            testCase.verifyEqual(expected_result.network_result, network_result{1});
        end

        function studentTTest(testCase)
            edge_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "pearson_result.mat")));
            testCase.tests.net_tests = {nla.net.test.StudentTTest()};
            network_result = testCase.tests.runNetTestsPerm(testCase.network_test_options, testCase.edge_test_options.net_atlas, edge_result.edge_result);
            
            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "student_t_result.mat")));
            testCase.verifyEqual(expected_result.network_result, network_result{1});
        end

        function welchTTest(testCase)
            edge_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "pearson_result.mat")));
            testCase.tests.net_tests = {nla.net.test.WelchTTest()};
            network_result = testCase.tests.runNetTestsPerm(testCase.network_test_options, testCase.edge_test_options.net_atlas, edge_result.edge_result);
            
            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "welch_t_result.mat")));
            testCase.verifyEqual(expected_result.network_result, network_result{1});
        end

        function wilcoxonTest(testCase)
            edge_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "pearson_result.mat")));
            testCase.tests.net_tests = {nla.net.test.WilcoxonTest()};
            network_result = testCase.tests.runNetTestsPerm(testCase.network_test_options, testCase.edge_test_options.net_atlas, edge_result.edge_result);
            
            expected_result = load(strcat(testCase.root_path, fullfile("+nla", "unittests", "wilocoxon_result.mat")));
            testCase.verifyEqual(expected_result.network_result, network_result{1});
        end
    end
end