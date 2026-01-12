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
            [rows, columns] = size(orig_input_struct.permutation_groups);
            palm_permutation_groups = [];
            all_negative_ones = -1 .* ones(rows, 1);
            for column = 1:columns
                current_column = orig_input_struct.permutation_groups(:, column);
                unique_values = unique(current_column);
                % PALM/quickperm does not like '0' being a member of the groups. If it is, we just increment all the numbers
                if ismember(0, unique_values)
                    current_column = current_column + 1;
                    unique_values = unique(current_column);
                end

                % PALM/quickperm needs each grouping to have a running tally of all the numbers
                counts = containers.Map(unique_values, ones(1, numel(unique_values)));
                tally_column = zeros(rows, 1);
                for row_num = 1:rows
                    tally_column(row_num) = counts(current_column(row_num));
                    counts(current_column(row_num)) = counts(current_column(row_num)) + 1;
                end

                palm_permutation_groups = [palm_permutation_groups all_negative_ones];
                palm_permutation_groups = [palm_permutation_groups current_column];
                palm_permutation_groups = [palm_permutation_groups tally_column];
            end
            orig_input_struct.permutation_groups = palm_permutation_groups;
            [permutations, ~] = nla.lib.palm_quickperms(orig_input_struct.behavior, orig_input_struct.permutation_groups, number_permutations);
            orig_input_struct.permutations = permutations;
        end
    end
end