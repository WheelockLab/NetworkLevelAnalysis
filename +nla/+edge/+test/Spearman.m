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
        
        function result = run(obj, input_struct)
            [rho_vec, p_vec] = corr(input_struct.behavior, input_struct.func_conn.v', 'type', 'Spearman');
            result = obj.composeResult(nla.fisherR2Z(rho_vec'), p_vec', input_struct.prob_max);
        end
    end
end

