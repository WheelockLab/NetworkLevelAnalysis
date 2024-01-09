classdef NetworkTestsTestCase < matlab.unittest.TestCase

    properties
        variables
    end

    methods (TestClassSetup)
        function loadInputData(testCase)
            load(fullfile("nla", "net", "tests", "edgeTestInputStruct.mat"), "input_struct");
            load(fullfile("nla", "edge", "tests", "edgeKendallBResult.mat"), "result");
            testCase.variables.input_struct = input_struct;
            testCase.variables.edge_result = result;
        end
    end

    methods (TestClassTeardown)
        function clearData(testCase)
            clear testCase.variables
        end
    end

    methods (Test)
        function chiSquaredTest(testCase)
            import nla.net.test.ChiSquared
            chi_squared = ChiSquared();
            expected = chi_squared.run(testCase.variables.input_struct, testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestChiSquaredResult.mat"));
            testCase.verifyEqual(actual.result, expected);
        end

        function cohenDTest(testCase)
            import nla.net.test.CohenD
            cohenD = CohenD();
            expected = cohenD.run(testCase.variables.input_struct, testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestCohenDResult.mat"));
            testCase.verifyEqual(actual.result, expected);
        end

        function hyperGeometricTest(testCase)
            import nla.net.test.HyperGeo
            hyper_geo = HyperGeo();
            expected = hyper_geo.run(testCase.variables.input_struct, testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestHyperGeoResult.mat"));
            testCase.verifyEqual(actual.result, expected);
        end

        function kolmogorovSmirnovTest(testCase)
            import nla.net.test.KolmogorovSmirnov
            k_s = KolmogorovSmirnov();
            expected = k_s.run(testCase.variables.input_struct, testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestKolmogorovSmirnovResult.mat"));
            testCase.verifyEqual(actual.result, expected);
        end

        function studentTTest(testCase)
            import nla.net.test.StudentT
            student_t = StudentT();
            expected = student_t.run(testCase.variables.input_struct, testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestStudentTResult.mat"));
            testCase.verifyEqual(actual.result, expected);
        end

        function welchTTest(testCase)
            import nla.net.test.WelchT
            welch_t = WelchT();
            expected = welch_t.run(testCase.variables.input_struct, testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestWelchTResult.mat"));
            testCase.verifyEqual(actual.result, expected);
        end

        function wilcoxonTest(testCase)
            import nla.net.test.Wilcoxon
            wilcoxon = Wilcoxon();
            expected = wilcoxon.run(testCase.variables.input_struct, testCase.variables.edge_result, testCase.variables.input_struct.net_atlas);
            actual = load(fullfile("nla", "net", "tests", "networkTestWilcoxonResult.mat"));
            testCase.verifyEqual(actual.result, expected);
        end
    end
end
