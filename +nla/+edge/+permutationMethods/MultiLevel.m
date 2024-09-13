classdef MultiLevel < nla.edge.permutationMethods.Base
    %MULTILEVEL Multilevel permutation method
    %
    % multi-level strategy = multiLevel()
    % multi-level strategy = the object which will be doing the permutations the data. The functional
    %   connectivity is permuted
    % 
    % needed for methods:
    % test_options = this is the options and data for the tests being run. Sometimes called 'input_struct'
    %
    % How this works: THe object controls the permutations. It can be instantiated without any data
    % Before permutations can be run, a permutation tree needs to be created. This needs to be done with the
    % "createPermutationTree(test_options)" method. This creates a permutation tree (with the nodes). It
    % also will find all the "terminal nodes" - the nodes that have no children. These are the last groupings
    % and the actual data to be permuted
    %
    % After the tree is created (this only is done once), the object is ready to do the permutations.
    % This is done by taking each terminal node, getting the current indexes of the data, permuting them, 
    % and then applying these indexes to the data.

    properties
        permutation_tree
        terminal_nodes = []
    end

    methods
        function obj = MultiLevel()
        end

        function obj = createPermutationTree(obj, input_struct)
            if ~isfield(input_struct, "permutation_groups")
                input_struct.permutation_groups = [];
            end
            obj.permutation_tree = nla.edge.permutationMethods.tree.PermutationTree(...
                input_struct.func_conn.v, input_struct.permutation_groups...
            );
            tree_root = obj.permutation_tree.root_node;
            obj = obj.depthFirstSearch(tree_root);
        end

        function permuted_input_struct = permute(obj, orig_input_struct)
            permuted_input_struct = orig_input_struct;
            permuted_transposed_functional_connectivity = zeros(size(orig_input_struct.func_conn.v'));

            for node_index = 1:numel(obj.terminal_nodes)
                node = obj.terminal_nodes(node_index);
                current_indexes = node.data_with_indexes{2};
                original_indexes = node.data_with_indexes{3};
                data = node.data_with_indexes{1}'; % transpose to match dimensions of indexes
                
                permuted_indexes = nla.helpers.permuteVector(current_indexes);
                sorted_original_indexes = sort(original_indexes, 2);
                original_indexes = original_indexes(permuted_indexes);
                data = data(permuted_indexes, :);
                node.data_with_indexes = {data', current_indexes, original_indexes};
                permuted_transposed_functional_connectivity(sorted_original_indexes, :) = data;
            end

            permuted_input_struct.func_conn.v = permuted_transposed_functional_connectivity';
        end

        function obj = depthFirstSearch(obj, node_input)
            node_queue = [node_input];
            while ~isempty(node_queue)
                node = node_queue(1);
                if isempty(node.children)
                    obj.terminal_nodes = [obj.terminal_nodes, node];
                else
                    for child = 1:numel(node.children)
                        node_queue = [node_queue; node.children(child)];
                    end
                end
                if size(node_queue, 1) > 1
                    node_queue = node_queue(2:end, :);
                else
                    node_queue = [];
                end
            end
        end
    end
end