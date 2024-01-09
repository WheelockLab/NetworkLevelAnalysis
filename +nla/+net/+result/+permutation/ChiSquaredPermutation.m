classdef ChiSquaredPermutation < handle
    % CHISQUAREDPERMUTATION Collection of permutation results for chi-squared tests

    properties (Constant)
        name = "Chi-Squared Permutations"
        name_formatted = "\chi^2 permutations"
        test = "Chi-squared"
        significance_function = @ge
        statistic = 'chi2_permutations'
        single_sample_statistic = 'chi2_permutations'
        has_full_conn = true
        has_nonpermuted = true
        has_within_net_pair = true
    end

    properties (Access = protected)
        last_index = 0;
    end

    properties
        chi2_permutations
        observed_greater_than_expected_permutations
        probability_permutations
        single_sample_probability_permutations
    end

    methods
        function obj = ChiSquaredPermutation()
        end

        function object_copy = copy(obj)
            object_copy = nla.net.result.permutation.ChiSquaredPermutation();

            object_copy.chi2_permutations = copy(obj.chi2_permutations);
            object_copy.observed_greater_than_expected_permutations = copy(obj.observed_greater_than_expected_permutations);
            object_copy.probability_permutations = copy(obj.probability_permutations);
            object_copy.single_sample_probability_permutations = copy(obj.single_sample_probability_permutations);
        end

        function merge(obj, other_results)
            for index = 1:numel(other_results)
                obj.chi2_permutations.v = [obj.chi2_permutations.v, other_results{index}.chi2_permutations.v];
                obj.observed_greater_than_expected_permutations.v = [obj.observed_greater_than_expected_permutations.v, other_results{index}.observed_greater_than_expected_permutations.v];
                obj.probability_permutations.v = [obj.probability_permutations.v, other_results{index}.probability_permutations.v];
                obj.single_sample_probability_permutations.v = [obj.single_sample_probability_permutations.v, other_results{index}.single_sample_probability_permutations.v];
            end
        end

        function concatenateResult(obj, network_result)
            if isempty(obj.chi2_permutations)
                obj.chi2_permutations = nla.TriMatrix(network_result.chi2.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.observed_greater_than_expected_permutations = nla.TriMatrix(network_result.observed_gt_expected.size, 'logical', nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.probability_permutations = nla.TriMatrix(network_result.prob.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
                obj.single_sample_probability_permutations = nla.TriMatrix(network_result.prob.size, nla.TriMatrixDiag.KEEP_DIAGONAL);
            end
            obj.chi2_permutations.v(:, obj.last_index + 1) = network_result.chi2.v;
            obj.observed_greater_than_expected_permutations.v(:, obj.last_index + 1) = network_result.observed_gt_expected.v;
            obj.probability_permutations.v(:, obj.last_index + 1) = network_result.prob.v;
            obj.single_sample_probability_permutations.v(:, obj.last_index + 1) = network_result.prob.v;

            obj.last_index = obj.last_index + 1;
        end
    end
end