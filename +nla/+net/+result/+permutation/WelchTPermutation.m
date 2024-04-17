classdef WelchTPermutation < handle
    % WELCHTPERMUTATION A collection of permutation results from Welch's T tests


    properties (Constant)
        name = "Welch's T Permutations"
        name_formatted = "Welch's T Permutations"
        test = "Welch's T"
        significance_function = @nla.helpers.abs_ge
        statistic = 't_permutations'
        single_sample_statistic = 'single_sample_t_permutations'
        has_full_conn = true
        has_nonpermuted = true
        has_within_net_pair = true
    end

    properties (Access = private)
        last_index = 0
    end

    properties
        t_permutations = []
        single_sample_t_permutations = []
        probability_permutations = []
        single_sample_probability_permutations = []
    end

    methods
        function obj = WelchTPermutation()
        end

        function copy_object = copy(obj)
            copy_object = nla.net.result.permutation.WelchTPermutation();
            copy_object.t_permutations = copy(obj.t_permutations);
            copy_object.single_sample_t_permutations = copy(obj.single_sample_t_permutations);
            copy_object.probability_permutations = copy(obj.probability_permutations);
            copy_object.single_sample_probability_permutations = copy(obj.single_sample_probability_permutations);
        end

        function merge(obj, other_results)
            for index = 1:numel(other_results)
                obj.t_permutations.v = [obj.t_permutations.v, other_results{index}.t_permutations.v];
                obj.single_sample_t_permutations.v = [obj.single_sample_t_permutations.v, other_results{index}.single_sample_t_permutations.v];
                obj.probability_permutations.v = [obj.probability_permutations.v, other_results{index}.probability_permutations.v];
                obj.single_sample_probability_permutations.v = [obj.single_sample_probability_permutations.v, other_results{index}.single_sample_probability_permutations.v];
            end
        end

        function concatenateResult(obj, network_result)
            if isempty(obj.t_permutations)
                obj.t_permutations = nla.TriMatrix(network_result.t.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.single_sample_t_permutations = nla.TriMatrix(network_result.ss_t.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.probability_permutations = nla.TriMatrix(network_result.prob.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.single_sample_probability_permutations = nla.TriMatrix(network_result.ss_prob.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
            end

            obj.t_permutations.v(:, obj.last_index + 1) = network_result.t.v;
            obj.single_sample_t_permutations.v(:, obj.last_index + 1) = network_result.ss_t.v;
            obj.probability_permutations.v(:, obj.last_index + 1) = network_result.prob.v;
            obj.single_sample_probability_permutations.v(:, obj.last_index + 1) = network_result.ss_prob.v;
            
            obj.last_index = obj.last_index + 1;
        end
    end
end