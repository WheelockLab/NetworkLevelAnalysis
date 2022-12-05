classdef Pearson < nla.edge.BaseTest
    %PEARSON Edge-level Pearson correlation
    properties (Constant)
        name = "Pearson's r"
        coeff_name = "Pearson's r (Fisher-Z Transformed)"
    end
    
    methods
        function obj = Pearson()
            import nla.* % required due to matlab package system quirks
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct)
            [r_vec, p_vec] = corr(input_struct.behavior, input_struct.func_conn.v', 'type', 'Pearson');       
            result = obj.composeResult(nla.fisherR2Z(r_vec'), p_vec', input_struct.prob_max);
        end
    end
end

