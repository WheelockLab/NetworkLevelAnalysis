classdef CohenDPermutation < handle
    % COHENDPERMUTATION A collection of permutation results from Cohen's D tests

    properties (Constant)
        name = "Cohen's D Permutations"
        name_formatted = "Cohen's D Permutations"
        test = "Cohen's D"
        significance_function = @ge
        statistic = 'd_permutations'
        has_within_net_pair = true
        has_full_conn = true
        has_nonpermuted = false
        histogram = false
    end

    properties
        d_permutations = []
        within_network_pair_d_permutations = []
    end

    properties (Access = private)
        last_index = 0
    end

    methods
        function obj = CohenDPermutation()
        end

        function copy_object = copy(obj)
            copy_object = nla.net.result.permutation.CohenDPermutation();
            copy_object.d_permutations = copy(obj.d_permutations);
            copy_object.within_network_pair_d_permutations = copy(obj.within_network_pair_d_permutations);
        end

        function merge(obj, other_results)
            for index = 1:numel(other_results)
                obj.d_permutations.v = [obj.d_permutations.v, other_results{index}.d_permutations.v];
                obj.within_network_pair_d_permutations.v = [obj.within_network_pair_d_permutations.v, other_results{index}.within_network_pair_d_permutations.v];
            end
        end

        function concatenateResult(obj, network_result)
            if isempty(obj.d_permutations)
                obj.d_permutations = nla.TriMatrix(network_result.d.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.within_network_pair_d_permutations = nla.TriMatrix(network_result.within_np_d.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
            end

            obj.d_permutations.v(:, obj.last_index + 1) = network_result.d.v;
            obj.within_network_pair_d_permutations.v(:, obj.last_index + 1) = network_result.within_np_d.v;

            obj.last_index = obj.last_index + 1;
        end
    end
end