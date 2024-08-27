classdef PermutationTree < handle

    properties
        permutation_groups
        data_with_indexes = [] % This is going to be three values [data value, original index, current index]
        children = []
    end

    properties (SetAccess = immutable)
        original_input_data
    end

    methods
        function obj = PermutationTree(permutation_groups, input_data)
            obj.permutation_groups = permutation_groups;
            obj.original_input_data = input_data;
            for index = 1:numel(input_data(:, 1))
                size_input_data = size(input_data);
                if size(size_input_data(:, 2) == 1) % if data input is original single column
                    obj.data_with_indexes = [obj.data_with_indexes; input_data(index), index, index];
                else % if data is another tree
                    obj.data_with_indexes = [obj.data_with_indexes; input_data(index, 1), input_data(index, 2), index];
                end
            end
            obj = obj.createTree();
        end

        function obj = createTree(obj)
            groups = unique(obj.permutation_groups(:, 1));
            if size(obj.permutation_groups, 2) > 1
                for group = 1:numel(groups)
                    group_indexes = find(obj.permutation_groups(:, 1) == group);
                    new_tree = PermutationTree(obj.permutation_groups(group_indexes, 2:end), obj.data_with_indexes(group_indexes, :));
                    obj.children = [obj.children; new_tree];
                end
            end
        end
    end
end