classdef PermutationNode < handle


    properties
        children = []
        level = 0 % 0 is root, initial_data
        parent = false % if false, this is the root of the tree
        data_with_indexes = {}
        permutation_groups = []
    end

    properties (SetAccess = immutable)
        original_data % matrix of size input_data.length x 3 with each row [data_value, current_index, original_index]
    end

    methods
        function obj = PermutationNode(level, input_data, permutation_groups)
            % Inputs:
            % input_data is the functional connectivity with each subject as a vector. Size: [edges(?) x subjects]
            % permutation groups. This will be a matrix with each level of permutation a vector. Size: [subjects x levels of permutations]

            if isequal(level, 0)
                obj.permutation_groups = permutation_groups;
                obj.original_data = {input_data, [1:size(input_data, 2)'], [1:size(input_data, 2)']};
                obj.data_with_indexes = obj.original_data;
            else
                size_permutation_groups = size(permutation_groups);
                if size_permutation_groups(2) > 1
                    obj.permutation_groups = permutation_groups(:, 2:end);
                end
                functional_connectivity = input_data{1};
                current_index = input_data{2};
                original_index = input_data{3};
                obj.original_data = {functional_connectivity, current_index', original_index'};
                obj.data_with_indexes = obj.original_data;
            end
            if ~isempty(obj.permutation_groups)
                group_numbers = unique(obj.permutation_groups(:, 1));
                for group_number = 1:numel(group_numbers)
                    group_indexes = (obj.permutation_groups(:, 1) == group_numbers(group_number));
                    temp_permutation_groups = obj.permutation_groups(group_indexes, :);
                    group_input_data = obj.data_with_indexes{1};
                    group_current_indexes = obj.data_with_indexes{2};
                    group_original_indexes = obj.data_with_indexes{3};
                    group_data = {group_input_data(:, group_indexes), group_current_indexes(group_indexes), group_original_indexes(group_indexes)};
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