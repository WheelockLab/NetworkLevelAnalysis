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
        
        function result = run(obj, input_struct, previous_result)
            import nla.* % required due to matlab package system quirks
            behavior = permuteBehavior(input_struct.behavior, previous_result);
            [r_vec, p_vec] = corr(behavior, input_struct.func_conn.v', 'type', 'Pearson');
            result = obj.updateResult(input_struct, fisherR2Z(r_vec'), p_vec', previous_result);
        end
    end
end

