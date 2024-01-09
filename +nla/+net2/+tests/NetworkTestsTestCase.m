classdef NetworkTestsTestCase < matlab.unittest.TestCase

    properties
        variables
    end

    methods (TestClassSetup)
        function loadInputData(testCase)
            load(fullfile("nla", "edge", "tests", "edgeTestInputStruct.mat"), "input_struct");
            load(fullfile("nla", "edge", "tests", "edgeKendallBResult.mat"), "result");
            testCase.variables.input_struct = input_struct;
            testCase.variables.edge_result = result;
        end
    end

    methods (TestClassTeardown)
        function clearData(testCase)
            clear testCase.variables;
        end
    end

    methods (Test)
        function chiSquaredTestTest(testCase)
            import nla.net2.test.ChiSquaredTest
            chi_squared_test = ChiSquaredTest();
            expected = chi_squared_test.run(testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestChiSquaredResult.mat"));
            % Rounding to 4 decimal places due to things close to 0 being off by 10^-10 or something tiny
            testCase.verifyEqual(round(actual.result.prob.v, 4), round(expected.p_value.v, 4));
            testCase.verifyEqual(round(actual.result.chi2.v, 4), round(expected.test_statistics.chi_squared.chi2_statistic.v, 4));
        end

        function hypergeometricTestTest(testCase)
            import nla.net2.test.HyperGeometricTest
            hypergeometric_test = HyperGeometricTest();
            expected = hypergeometric_test.run(testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestHyperGeoResult.mat"));
            testCase.verifyEqual(round(actual.result.prob.v, 4), round(expected.p_value.v, 4));
        end

        function kolmogorovSmirnovTestTest(testCase)
            import nla.net2.test.KolmogorovSmirnovTest
            k_s = KolmogorovSmirnovTest();
            expected = k_s.run(testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestKolmogorovSmirnovResult.mat"));
            testCase.verifyEqual(round(actual.result.prob.v, 4), round(expected.p_value.v, 4));
            testCase.verifyEqual(round(actual.result.ks.v, 4), round(expceted.test_statistics.kolmogorov_smirnov.ks_statistic.v, 4));
        end

        function studentTTestTest(testCase)
            import nla.net2.test.TTests
            student_t = TTests();
            expected = student_t.run(testCase.variables.edge_result, testCase.variables.input_struct.net_atlas, "students");
            actual = load(fullfile("nla", "net", "tests", "networkTestStudentTResult.mat"));
            testCase.verifyEqual(round(actual.result.prob.v, 4), round(expected.p_value.v, 4));
            testCase.verifyEqual(round(actual.result.t.v, 4), round(expected.test_statistics.students_t.t_statistic.v, 4));
        end

        function welchTTestTest(testCase)
            import nla.net2.test.TTests
            welch_t = TTests();
            expected = welch_t.run(testCase.variables.edge_result, testCase.variables.input_struct.net_atlas, "welchs");
            actual = load(fullfile("nla", "net", "tests", "networkTestWelchTResult.mat"));
            testCase.verifyEqual(round(actual.result.prob.v, 4), round(expected.p_value.v, 4));
            testCase.verifyEqual(round(actual.result.t.v, 4), round(expected.test_statistics.welchs_t.t_statistic.v, 4));
        end

        function wilcoxonTestTest(testCase)
            import nla.net2.test.WilcoxonTest
            wilcoxon_test = WilcoxonTest();
            expected = wilcoxon_test.run(testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestWilcoxonResult.mat"));
            testCase.verifyEqual(round(actual.result.prob.v, 4), round(expected.p_value.v, 4));
            testCase.verifyEqual(round(actual.result.w.v, 4), round(expected.test_statistics.wilcoxon.ranksum_statistic.v, 4));
        end
    end
end