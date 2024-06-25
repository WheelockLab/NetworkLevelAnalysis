classdef PermutationMethodsTest < matlab.unittest.TestCase
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
            clear
        end
    end

    methods (Test)
        function behaviorVecTest(testCase)
            permutation_method = nla.edge.permutationMethods.BehaviorVec();
            permuted_input_struct = permutation_method.permute(testCase.variables.input_struct);
            
            testCase.verifyNotEqual(testCase.variables.input_struct.behavior, permuted_input_struct.behavior);

            [counts, original_values] = groupcounts(testCase.variables.input_struct.behavior);
            [permuted_counts, permuted_values] = groupcounts(permuted_input_struct.behavior);
            testCase.verifyEqual(counts, permuted_counts);
            testCase.verifyEqual(original_values, permuted_values);
        end
    end
end