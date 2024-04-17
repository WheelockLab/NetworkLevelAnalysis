classdef KolmogorovSmirnovPermutation < handle
    % KOLMOGOROVSMIRNOVPERMUTATION A collection of permutation results from Komogorov-Smirnov tests

    properties (Constant)
        name = "Kolmogorov-Smirnov Permutations"
        name_formatted = "KS Permutations"
        test = "Kolmogorov-Smirnov"
        significance_function = @ge
        statistic = 'ks_permutations'
        single_sample_statistic = 'single_sample_ks_permutations'
        has_full_conn = true
        has_nonpermuted = true
        has_within_net_pair = true
    end

    properties (Access = private)
        last_index = 0
    end

    properties
        ks_permutations
        single_sample_ks_permutations
        probability_permutations
        single_sample_probability_permutations
    end

    methods
        function obj = KolmogorovSmirnovPermutation()
        end

        function copy_object = copy(obj)
            copy_object = nla.net.result.permutation.KolmogorovSmirnovPermutation();
            copy_object.ks_permutations = copy(obj.ks_permutations);
            copy_object.single_sample_ks_permutations = copy(obj.single_sample_ks_permutations);
            copy_object.probability_permutations = copy(obj.probability_permutations);
            copy_object.single_sample_probability_permutations = copy(obj.single_sample_probability_permutations);
        end

        function merge(obj, other_results)
            for index = 1:numel(other_results)
                obj.ks_permutations.v = [obj.ks_permutations.v, other_results{index}.ks_permutations.v];
                obj.single_sample_ks_permutations.v = [obj.single_sample_ks_permutations.v, other_results{index}.ks_permutations.v];
                obj.probability_permutations.v = [obj.probability_permutations.v, other_results{index}.probability_permutations.v];
                obj.single_sample_probability_permutations.v = [obj.single_sample_probability_permutations.v, other_results{index}.single_sample_probability_permutations.v];
            end
        end

        function concatenateResult(obj, network_result)
            if isempty(obj.ks_permutations)
                obj.ks_permutations = nla.TriMatrix(network_result.ks.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.single_sample_ks_permutations = nla.TriMatrix(network_result.ss_ks.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.probability_permutations = nla.TriMatrix(network_result.prob.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.single_sample_probability_permutations = nla.TriMatrix(network_result.ss_prob.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
            end

            obj.ks_permutations.v(:, obj.last_index + 1) = network_result.ks.v;
            obj.single_sample_ks_permutations.v(:, obj.last_index + 1) = network_result.ss_ks.v;
            obj.probability_permutations.v(:, obj.last_index + 1) = network_result.prob.v;
            obj.single_sample_probability_permutations.v(:, obj.last_index + 1) = network_result.ss_prob.v;
            obj.last_index = obj.last_index + 1;
        end
    end
end