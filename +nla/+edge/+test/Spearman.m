classdef Spearman < nla.edge.BaseTest
    %SPEARMAN Edge-level Spearman correlation
    properties (Constant)
        name = "Spearman's rho"
        coeff_name = "Spearman's rho (Fisher-Z Transformed)"
    end
    
    methods
        function obj = Spearman()
            import nla.* % required due to matlab package system quirks
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct, previous_result)
            import nla.* % required due to matlab package system quirks
            behavior = permuteBehavior(input_struct.behavior, previous_result);
            [rho_vec, p_vec] = corr(behavior, input_struct.func_conn.v', 'type', 'Spearman');
            result = obj.updateResult(input_struct, fisherR2Z(rho_vec'), p_vec', previous_result);
        end
    end
end

