classdef TestPoolTest < matlab.unittest.TestCase

    properties
        variables
    end

    methods (TestClassSetup)
        function loadTestData(testCase)

        end
    end

    methods (TestClassTeardown)
        function clearTestData(testCase)
            clear 
        end
    end

    methods (Test)
        function permutationEdgeTest(testCase)
            import nla.TestPool
            
            test_pool = TestPool();

        end
    end
end