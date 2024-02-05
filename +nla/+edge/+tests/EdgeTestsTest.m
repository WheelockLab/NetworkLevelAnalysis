classdef EdgeTestsTest < matlab.unittest.TestCase

    properties
        variables
    end
    
    methods (TestClassSetup)
        function loadTestData(testCase)
            testCase.variables = load("edgeTestInputStruct.mat");
        end
    end
    
    methods (TestClassTeardown)
        function clearTestData(testCase)
            clear testCase.variables
        end
    end

    methods (Test)
        function kendallBTest(testCase)
            import nla.edge.test.KendallB
            % Your guess is as good as mine on why I need the full path
            % here and not above
            load(fullfile("nla", "edge", "tests", "edgeKendallBResult.mat"), "result");
            kendallB = KendallB();
            expected = kendallB.run(testCase.variables.input_struct);
            testCase.verifyEqual(result, expected);
        end

        function pearsonTest(testCase)
            import nla.edge.test.Pearson
            load(fullfile("nla", "edge", "tests", "edgePearsonResult.mat"), "result");
            pearson = Pearson();
            expected = pearson.run(testCase.variables.input_struct);
            testCase.verifyEqual(result, expected);
        end

        function spearmanTest(testCase)
            import nla.edge.test.Spearman
            load(fullfile("nla", "edge", "tests", "edgeSpearmanResult.mat"), "result");
            spearman = Spearman();
            expected = spearman.run(testCase.variables.input_struct);
            testCase.verifyEqual(result, expected);
        end

        function spearmanEstimatorTest(testCase)
            import nla.edge.test.SpearmanEstimator
            load(fullfile("nla", "edge", "tests", "edgeSpearmanEstimatorResult.mat"), "result");
            spearman_estimator = SpearmanEstimator();
            expected = spearman_estimator.run(testCase.variables.input_struct);
            testCase.verifyEqual(result, expected);
        end
    end

end