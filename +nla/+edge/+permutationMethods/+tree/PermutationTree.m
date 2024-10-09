classdef PermutationTree < handle
    %PERMUTATIONTREE Base class for permutation groups. This just bundles all the permutation nodes
    % together for ease. 
    %
    % tree = PermutationTree(input_data, permutation_groups)
    % tree = The tree object. Consists of the raw permutation groups along with the raw data along
    %   starting indexes
    % 
    % input_data = The data that is permuted. This is usually the functional connectivity (right now, that's all it works for)
    % permutation_groups = the columns from the csv file that characterizes the permutation groupings
    %   Each column of the data is 1 permutation grouping. 
    %   Each row is one subject/data entry
    %   Values should be positive integers. Groups must be independent in each column

    properties
        permutation_groups % Raw from the behavior table to define permutation grouping
        root_node % The first "level 0" node of the tree
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