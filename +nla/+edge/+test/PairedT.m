classdef PairedT < nla.edge.BaseTest
    %PAIREDT Edge-level Paired T-test

    properties (Constant)
        name = "Paired T"
        coeff_name = "Paired T"
    end

    methods
        function obj = PairedT()
            obj@nla.edge.BaseTest();
        end

        function result = run(obj, test_options)
            % This function calculates the t-test between 2 sets of data to determine whether the mean
            % difference is zero.

            group1 = (test_options.behavior == test_options.group1_val);
            group2 = (test_options.behavior == test_options.group2_val);

            total_size = sum(group1) + sum(group2);

            x = test_options.func_conn.v(:, group1);
            y = test_options.func_conn.v(:, group2);

            [~, p_values, ~, stats] = ttest2(x, y);

            group_names = {test_options.group1_name, test_options.grou2_name};
            % We're going to go with the same result class as the Welch's T
            result = nla.edge.result.WelchT(test_options.func_conn_size, test_options.prob_max, group_names);
            obj.setResultFields(test_options.net_atlas, result, stats.tstat, p_values, test_options.prob_max);
            result.dof.v = stats.df;

            t_significance = tinv(1 - (test_options.prob_max / 2), total_size - 2);
            result.prob_sig.v = (abs(stats.tstat) > t_significance);
            result.avg_prob_sig = sum(result.prob_sig.v) ./ numel(result.prob_sig.v);
        end
    end

    methods (Static)
        function inputs = requiredInputs()
            inputs = requiredInputs@nla.edge.BaseTest();

            behavior_handle = nla.helpers.firstInstanceOfClass(inputs, 'nla.inputField.Behavior');
            behavior_handle.covariates_enabled = nla.inputField.CovariatesEnabled.ONLY_FC;

            inputs{end + 1} = nla.inputField.String('group1_name', 'Group 1 name:', 'Group1');
            inputs{end + 1} = nla.inputField.Number('group1_val', 'Group 1 behavior value:', -Inf, 1, Inf);
            inputs{end + 1} = nla.inputField.String('group2_name', 'Group 2 name:', 'Group2');
            inputs{end + 1} = nla.inputField.Number('group2_val', 'Group 2 behavior value:', -Inf, 0, Inf);
        end
    end
end