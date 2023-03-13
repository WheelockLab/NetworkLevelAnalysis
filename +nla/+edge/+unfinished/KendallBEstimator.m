classdef KendallBEstimator < nla.edge.BaseTest
    %KENDALL Edge-level Kendall's tau estimator
    properties (Constant)
        name = "Kendall's tau-b (Estimator)"
        coeff_name = "Kendall's tau-b (Estimated)"
    end
    
    methods
        function obj = KendallBEstimator()
            import nla.* % required due to matlab package system quirks
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct)
            import nla.* % required due to matlab package system quirks
            
            tic;
            [tau_vec_correct, p_vec_correct] = corr(input_struct.behavior, input_struct.func_conn.v', 'type', 'Kendall');
            t1 = toc;
            t1
            
            tic;
            num_pairs = size(input_struct.func_conn.v, 1);
            tau_vec = zeros(num_pairs, 1);
            p_vec = zeros(num_pairs, 1);
            for i = [1:num_pairs]
                [tau_vec(i), p_vec(i)] = helpers.kendallEstimator(input_struct.behavior, input_struct.func_conn.v(i, :));
                
                
                ktaub(datain, alpha, wantplot)

            end
            t2 = toc;
            t2
            
            result = obj.composeResult(tau_vec', p_vec', input_struct.prob_max);
        end
    end
end