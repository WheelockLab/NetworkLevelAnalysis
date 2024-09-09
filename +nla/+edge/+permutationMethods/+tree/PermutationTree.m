classdef PermutationTree < handle

    properties
        permutation_groups
    end

    properties (setAccess = immutable)
        original_data % This is going to be a matrix of input_data.length x 3 [data_value, current_index_in_group, original_index]
    end

    methods
        function obj = PermutationTree(input_data, permutation_groups)
            obj.permutation_groups = permutation_groups;
            for index = 1:numels(input_data)
                obj.original_data(:, end + 1) = [input_data(index), index, index];
            end
        end
    end
end