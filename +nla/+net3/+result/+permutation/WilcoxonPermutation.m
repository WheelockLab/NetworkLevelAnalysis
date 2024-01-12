classdef WilcoxonPermutation < handle
    % WILCOXONPERMUTATION A collection of permutation results from Wilcoxon tests

    properties (Constant)
        name = "Wilcoxon Permutations"
        name_formatted = "Wilcoxon Permutations"
        test = "Wilcoxon rank-sum"
        significance_function = @nla.helpers.abs_ge
        statistic = 'z_permutations'
        single_sample_statistic = 'single_sample_w_permutations'
        has_full_conn = true
        has_nonpermuted = true
        has_within_net_pair = true
    end

    properties (Access = private)
        last_index = 0
    end

    properties
        w_permutations
        z_permutations
        single_sample_w_permutations
        probability_permutations
        single_sample_probability_permutations
    end

    methods
        function obj = WilcoxonPermutation()
        end

        function copy_object = copy(obj)
            copy_object = nla.net.result.permutation.WilcoxonPermutation();
            copy_object.w_permutations = copy(obj.w_permutations);
            copy_object.z_permutations = copy(obj.z_permutations);
            copy_object.single_sample_w_permutations = copy(obj.single_sample_w_permutations);
            copy_object.probability_permutations = copy(obj.probability_permutations);
            copy_object.single_sample_probability_permutations = copy(obj.single_sample_probability_permutations);
        end

        function merge(obj, other_results)
            for index = 1:numel(other_results)
                obj.w_permutations.v = [obj.w_permutations.v, other_results{index}.w_permutations.v];
                obj.z_permutations.v = [obj.z_permutations.v, other_results{index}.z_permutations.v];
                obj.single_sample_w_permutations.v = [obj.single_sample_w_permutations.v, other_results{index}.single_sample_w_permutations.v];
                obj.probability_permutations.v = [obj.probability_permutations.v, other_results{index}.probability_permutations.v];
                obj.single_sample_probability_permutations.v = [obj.single_sample_probability_permutations.v, other_results{index}.single_sample_probability_permutations.v];
            end
        end

        function concatenateResult(obj, network_result)
            if isempty(obj.w_permutations)
                obj.w_permutations = nla.TriMatrix(network_result.w.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.z_permutations = nla.TriMatrix(network_result.z.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.single_sample_w_permutations = nla.TriMatrix(network_result.ss_w.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.probability_permutations = nla.TriMatrix(network_result.prob.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.single_sample_probability_permutations = nla.TriMatrix(network_result.ss_prob.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
            end

            obj.w_permutations.v(:, obj.last_index + 1) = network_result.w.v;
            obj.z_permutations.v(:, obj.last_index + 1) = network_result.z.v;
            obj.single_sample_w_permutations.v(:, obj.last_index + 1) = network_result.ss_w.v;
            obj.probability_permutations.v(:, obj.last_index + 1) = network_result.prob.v;
            obj.single_sample_probability_permutations.v(:, obj.last_index + 1) = network_result.ss_prob.v;

            obj.last_index = obj.last_index + 1;
        end
    end
end