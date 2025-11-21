classdef Quickperms < nla.edge.permutationMethods.Base
    %QUICKPERMS Implementation of Palm's quickperms method
    %
    %

    properties
        permutation_count = 0
    end

    methods
        function obj = Quickperms()
        end

        function permuted_input_struct = permute(obj, orig_input_struct)
            permuted_input_struct = copy(orig_input_struct);
            permuted_input_struct.behavior = orig_input_struct.behavior(orig_input_struct.permutations(obj.permutation_count + 1));
            obj.permutation_count = obj.permutation_count + 1;
        end

        function extended_input_struct = createPermutations(obj, orig_input_struct, number_permutations)
            extended_input_struct = orig_input_struct;
            [permutations, ~] = nla.lib.palm_quickperms(orig_input_struct.behavior, orig_input_struct.permutation_groups, number_permutations);
            extended_input_struct.permutations = permutations;
        end
    end
end