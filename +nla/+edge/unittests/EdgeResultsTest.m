classdef EdgeResultsTest < matlab.unittest.TestCase
    properties
        variables
    end

    methods (TestClassSetup)
    end

    methods (TestClassTeardown)
        function clearTestData(testCase)
            clear
        end
    end

    methods (Test)
        function precalculatedInitTest(testCase)
            import nla.edge.result.Precalculated
            result = Precalculated();
            testCase.verifyEqual(result.coeff.size, uint32(2));
            testCase.verifyEqual(result.prob_max, -1);
        end

        function welchTInitTest(testCase)
            import nla.edge.result.WelchT
            result = WelchT();
            testCase.verifyEqual(result.prob_max, -1);

            result = WelchT(15, 1, {'group_1', 'group_2'});
            testCase.verifyEqual(result.coeff.size, uint32(15));
            testCase.verifyEqual(result.dof, nla.TriMatrix(15));
            testCase.verifyEqual(result.behavior_name, "group_1 > group_2");
            testCase.verifyEqual(result.coeff_range, [-3 3]);
        end
    end
end