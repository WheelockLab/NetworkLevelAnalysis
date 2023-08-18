classdef KendallB < nla.edge.BaseTest
    %KENDALL Edge-level Kendall's tau
    %   Very slow
    properties (Constant)
        name = "Kendall's tau-b"
        coeff_name = "Kendall's tau-b"
    end
    
    methods
        function obj = KendallB()
            import nla.* % required due to matlab package system quirks
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct)
            import nla.* % required due to matlab package system quirks
            [tau_vec, p_vec] = mex.run('kendallTauB', input_struct.behavior, input_struct.func_conn.v');
            result = obj.composeResult(tau_vec', p_vec', input_struct.prob_max);
        end
    end
end