classdef PermutationNode < handle

    properties
        children = []
        level = 0 % 0 is root, initial_data
        parent = false % if false, this is the root of the tree
        data_with_indexes = []
        permutation_groups = []
    end

    properties (SetAccess = immutable)
        original_data % matrix of size input_data.length x 3 with each row [data_value, current_index, original_index]
    end

    methods
        function obj = PermutationNode(level, input_data, permutation_groups)
            if isequal(level, 0)
                obj.permutation_groups = permutation_groups;
                for index = 1:numel(input_data(:, 1))
                    obj.original_data(end + 1, :) = [input_data(index), index, index];
                end
                obj.data_with_indexes = obj.original_data;
            else
                size_permutation_groups = size(permutation_groups);
                if size_permutation_groups(2) > 1
                    obj.permutation_groups = permutation_groups(:, 2:end);
                end
                for index = 1:numel(input_data(:, 1))
                    obj.original_data(end + 1, :) = [input_data(index, 1), input_data(index, 3), input_data(index, 3)];
                end
                obj.data_with_indexes = obj.original_data;
            end
            if ~isempty(obj.permutation_groups)
                group_numbers = unique(obj.permutation_groups(:, 1));
                for group_number = 1:numel(group_numbers)
                    group_indexes = (obj.permutation_groups(:, 1) == group_numbers(group_number));
                    temp_permutation_groups = obj.permutation_groups(group_indexes, :);
                    group_data = obj.data_with_indexes(group_indexes, :);
                    obj.children = [obj.children obj.createNodes(obj.level + 1, temp_permutation_groups, group_data, obj)];
                end
            end
        end

        function node = createNodes(obj, level, group_permutations, input_group_data, parent_node)
            node = nla.edge.permutationMethods.tree.PermutationNode(level, input_group_data, group_permutations);
            node.parent = parent_node;
        end
    end
end