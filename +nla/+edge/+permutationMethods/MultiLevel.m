classdef MultiLevel < nla.edge.permutationMethods.Base

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
            transposed_functional_connectivity = orig_input_struct.func_conn.v';
            permuted_transposed_functional_connectivity = zeros(size(transposed_functional_connectivity));

            for node_index = 1:numel(obj.terminal_nodes)
                node = obj.terminal_nodes(node_index);
                current_indexes = node.data_with_indexes{2};
                original_indexes = node.original_data{3};
                % start_index = original_indexes(1);
                % end_index = original_indexes(end);

                permuted_indexes = nla.helpers.permuteVector(current_indexes);
                node.data_with_indexes{2} = permuted_indexes;
                permuted_transposed_functional_connectivity(permuted_indexes, :) = transposed_functional_connectivity(current_indexes, :);;
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