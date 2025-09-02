classdef MultiLevelPermutationTest < matlab.unittest.TestCase

    properties
        test_options
    end

    methods (TestMethodSetup)
        function loadTestData(testCase)
            testCase.test_options = struct();
            testCase.test_options.behavior = [1:10]';
        end
    end

    methods (TestMethodTeardown)
        function clearTestData(testCase)
            clear
        end
    end

    methods (Test)
        function testPermutationNode(testCase)
            node = nla.edge.permutationMethods.tree.PermutationNode(0, testCase.test_options.behavior, []);
            testCase.verifyEqual(node.level, 0);
            testCase.verifyEqual(node.children, []);
            testCase.verifyEqual(node.parent, false);
            testCase.verifyEqual(node.original_data, node.data_with_indexes);
            expected_original_data = {[1:10]', [1:10]'};
            testCase.verifyEqual(node.original_data, expected_original_data);
        end

        function testPermutationTree(testCase)
            tree = nla.edge.permutationMethods.tree.PermutationTree(testCase.test_options.behavior, []);
            testCase.verifyClass(tree, 'nla.edge.permutationMethods.tree.PermutationTree');
            testCase.verifyClass(tree.root_node, 'nla.edge.permutationMethods.tree.PermutationNode');
        end

        function testTwoPermutationGroups(testCase)
            testCase.test_options.permutation_groups = [1; 1; 1; 1; 1; 2; 2; 2; 2; 2];
            tree = nla.edge.permutationMethods.tree.PermutationTree(testCase.test_options.behavior, testCase.test_options.permutation_groups);
            testCase.verifyEqual(size(tree.root_node.children, 2), 2);
            testCase.verifyEqual(tree.root_node, tree.root_node.children(1).parent);
            testCase.verifyEqual(tree.root_node, tree.root_node.children(2).parent);
            testCase.verifyEqual(tree.root_node.children(1).original_data{2}, [1:5]');
            testCase.verifyEqual(tree.root_node.children(2).original_data{2}, [6:10]');
        end

        function testMultiLevel(testCase)
            testCase.test_options.permutation_groups = [1; 1; 1; 1; 1; 2; 2; 2; 2; 2];

            multi_level = nla.edge.permutationMethods.MultiLevel();
            multi_level = multi_level.createPermutationTree(testCase.test_options);
            tree = multi_level.permutation_tree;

            testCase.verifyClass(tree, 'nla.edge.permutationMethods.tree.PermutationTree');
            testCase.verifyEqual(size(multi_level.terminal_nodes, 2), 2);
        end

        function testPermute(testCase)
            testCase.test_options.permutation_groups = [1; 1; 1; 1; 1; 2; 2; 2; 2; 2];
            multi_level = nla.edge.permutationMethods.MultiLevel();
            multi_level = multi_level.createPermutationTree(testCase.test_options);

            original_options = testCase.test_options;
            permuted_options = multi_level.permute(testCase.test_options);
            testCase.verifyNotEqual(permuted_options.behavior, original_options.behavior);
            testCase.verifyEqual(sort(permuted_options.behavior(1:5)), [1:5]');
            testCase.verifyEqual(sort(permuted_options.behavior(6:10)), [6:10]');
        end

        function testMultiLevelTwoLevels(testCase)
            testCase.test_options.permutation_groups = [1, 1; 1, 1; 1, 2; 1, 2; 1, 2; 2, 3; 2, 3; 2, 3; 2, 4; 2, 4];
            multi_level = nla.edge.permutationMethods.MultiLevel();
            multi_level = multi_level.createPermutationTree(testCase.test_options);

            tree = multi_level.permutation_tree;
            terminal_nodes = multi_level.terminal_nodes;
            root = tree.root_node;

            testCase.verifyEqual(size(terminal_nodes, 2), 4);
            testCase.verifyClass(root.children(1).parent, 'nla.edge.permutationMethods.tree.PermutationNode');
            testCase.verifyEqual(size(root.children(1).children, 2), 2);
        end

        function testMultiLevelPermute(testCase)
            testCase.test_options.permutation_groups = [1, 1; 1, 1; 1, 2; 1, 2; 1, 2; 2, 3; 2, 3; 2, 3; 2, 4; 2, 4];
            multi_level = nla.edge.permutationMethods.MultiLevel();
            multi_level = multi_level.createPermutationTree(testCase.test_options);

            original_options = testCase.test_options;
            permuted_options = multi_level.permute(testCase.test_options);
            testCase.verifyNotEqual(permuted_options.behavior, original_options.behavior);
            testCase.verifyEqual(sort(permuted_options.behavior(1:2)), [1:2]');
            testCase.verifyEqual(sort(permuted_options.behavior(3:5)), [3:5]');
            testCase.verifyEqual(sort(permuted_options.behavior(6:8)), [6:8]');
            testCase.verifyEqual(sort(permuted_options.behavior(9:10)), [9:10]');
        end
    end
end