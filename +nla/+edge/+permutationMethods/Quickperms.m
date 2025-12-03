classdef Quickperms < nla.edge.permutationMethods.Base
    %QUICKPERMS Implementation of Palm's quickperms method
    %
    %

    properties
    end

    methods
        function obj = Quickperms()
        end

        function permuted_input_struct = permute(obj, orig_input_struct, permutation)
            permuted_input_struct = orig_input_struct;
            permuted_input_struct.behavior = orig_input_struct.behavior(orig_input_struct.permutations(:, permutation));
        end

        function orig_input_struct = createPermutations(obj, orig_input_struct, number_permutations)
            % Check if all values in first column of permutation struct are single value
            [rows, columns] = size(orig_input_struct.permutation_groups);
            unique_values = unique(orig_input_struct.permutation_groups(:, columns));
            counts = ones(max(unique_values),1);
            last_column = zeros(rows, 1);
            for row_num = 1:rows
                last_column(row_num) = counts(orig_input_struct.permutation_groups(row_num, columns));
                counts(orig_input_struct.permutation_groups(row_num, columns)) = counts(orig_input_struct.permutation_groups(row_num, columns)) + 1;
            end
            if ~all(orig_input_struct.permutation_groups(:, 1) == orig_input_struct.permutation_groups(1, 1))
                all_ones = ones(rows, 1);
                orig_input_struct.permutation_groups = [all_ones orig_input_struct.permutation_groups];
            end
            orig_input_struct.permutation_groups = [orig_input_struct.permutation_groups last_column];
            [permutations, ~] = nla.lib.palm_quickperms(orig_input_struct.behavior, orig_input_struct.permutation_groups, number_permutations);
            orig_input_struct.permutations = permutations;
        end
    end
end