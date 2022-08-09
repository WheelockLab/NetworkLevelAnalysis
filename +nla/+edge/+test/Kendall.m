classdef Kendall < nla.edge.BaseTest
    %KENDALL Edge-level Kendall's tau
    %   Very slow
    properties (Constant)
        name = "Kendall's tau"
        coeff_name = "Kendall's tau"
    end
    
    methods
        function obj = Kendall()
            import nla.* % required due to matlab package system quirks
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct, previous_result)
            import nla.* % required due to matlab package system quirks
            behavior = permuteBehavior(input_struct.behavior, previous_result);
            [tau_vec, p_vec] = corr(behavior, input_struct.func_conn.v', 'type', 'Kendall');
            result = obj.updateResult(input_struct, tau_vec', p_vec', previous_result);
        end
    end
end