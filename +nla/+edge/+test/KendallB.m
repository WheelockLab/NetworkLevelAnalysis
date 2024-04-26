classdef KendallB < nla.edge.BaseTest
    %KENDALL Edge-level Kendall's tau
    properties (Constant)
        name = "Kendall's tau-b"
        coeff_name = "Kendall's tau-b"
    end
    
    methods
        function obj = KendallB()
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct)
            [tau_vec, p_vec] = nla.mex.run('kendallTauB', input_struct.behavior, input_struct.func_conn.v');
            result = obj.composeResult(input_struct.net_atlas, tau_vec', p_vec', input_struct.prob_max);
        end
    end
end