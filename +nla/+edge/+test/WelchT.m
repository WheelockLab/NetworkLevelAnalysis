classdef WelchT < nla.edge.BaseTest
    %WELCHT Edge-level Welch T-test
    %   Differs slightly from built-in Welch's ttest (errors ~1e-13) but
    %   runs about 4x faster.
    properties (Constant)
        name = "Welch's T"
        coeff_name = "Welch's T"
    end
    
    methods
        function obj = WelchT()
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct)
            % This function calculates the t-test between 2 sets of data using the
            % Welch method that does not assume equal mean or variance or samples. The
            % function returns the t-statistic, p-value, and degrees of freedom.
            % The input data, X1 and X2, are assumed to be multi-dimensional arrays of
            % equal size except for the last dimension that represents
            % subjects/instances/etc.
            
            group1 = (input_struct.behavior == input_struct.group1_val);
            group2 = (input_struct.behavior == input_struct.group2_val);
            
            %total_size = size(input_struct.func_conn.v, 2)
            total_size = sum(group1) + sum(group2);
            
            x1 = input_struct.func_conn.v(:, group1);
            x2 = input_struct.func_conn.v(:, group2);
            
            [p_vec, t_vec, dof_vec] = nla.welchT(x1, x2);
            
            % Non-permuted
            group_names = {input_struct.group1_name, input_struct.group2_name};
            result = nla.edge.result.WelchT(input_struct.func_conn.size, input_struct.prob_max, group_names);
            obj.setResultFields(input_struct.net_atlas, result, t_vec, p_vec, input_struct.prob_max);
            result.dof.v = dof_vec;
            
            % Have to divide by 2 to get 2 tailed probability
%             t_sig = tinv(1 - (input_struct.prob_max / 2), total_size - 2);
%             result.prob_sig.v = (abs(t_vec) > t_sig);
            result.prob_sig.v =+ p_vec < input_struct.prob_max;
            result.avg_prob_sig = sum(result.prob.v(result.prob_sig.v == 1)) ./ numel(result.prob_sig.v);
        end
    end
    
    methods (Static)
        function inputs = requiredInputs()
            inputs = requiredInputs@nla.edge.BaseTest();
            
            % disable adding/modifying covariates in behavior
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

