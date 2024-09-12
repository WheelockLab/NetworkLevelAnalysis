classdef PermutationTree < handle

    properties
        permutation_groups
        root_node
    end

    properties (SetAccess = immutable)
        original_data = {} % This is going to be a matrix of input_data.length x 2 [data_value, original_index]
    end

    methods
        function obj = PermutationTree(input_data, permutation_groups)
            obj.original_data = {input_data, [1:size(input_data, 2)]'};
            obj.permutation_groups = permutation_groups;
            obj.root_node = nla.edge.permutationMethods.tree.PermutationNode(0, input_data, permutation_groups);
        end
    end
end