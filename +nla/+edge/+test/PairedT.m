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

            [~, p_values, ~, stats] = ttest(x, y, 'Dim', 2);

            group_names = {test_options.group1_name, test_options.group2_name};
            % We're going to go with the same result class as the Welch's T
            result = nla.edge.result.WelchT(test_options.func_conn.size, test_options.prob_max, group_names);
            obj.setResultFields(test_options.net_atlas, result, stats.tstat, p_values, test_options.prob_max);
            result.dof.v = stats.df;

            result.prob_sig.v =+ p_values < test_options.prob_max;
            result.avg_prob_sig = sum(result.prob.v(result.prob_sig.v == 1)) ./ numel(result.prob_sig.v);
            
            % Uncomment these lines only if you want to see sparsity values
            % for setting binarization threshold
%             num_hits = size(find(result.prob_sig.v == 1),1);
%             num_total = size(result.prob_sig.v,1);
%             sparsity = num_hits/num_total
        end
    end

    methods (Static)
        function inputs = requiredInputs()
            inputs = requiredInputs@nla.edge.BaseTest();

            behavior_handle = nla.helpers.firstInstanceOfClass(inputs, 'nla.inputField.Behavior');
            behavior_handle.covariates_enabled = nla.inputField.CovariatesEnabled.ONLY_FC;

            inputs{end + 1} = nla.inputField.Label("", "");
            inputs{end + 1} = nla.inputField.String('group1_name', 'Group 1 name:', 'Group1');
            inputs{end + 1} = nla.inputField.Number('group1_val', 'Group 1 behavior value:', -Inf, 1, Inf);
            inputs{end + 1} = nla.inputField.String('group2_name', 'Group 2 name:', 'Group2');
            inputs{end + 1} = nla.inputField.Number('group2_val', 'Group 2 behavior value:', -Inf, 0, Inf);
        end
    end
end