classdef WelchT < nla.net.BaseCorrResult
    %WELCHT The output result of a NetLevelWelchTTest
    
    properties (Constant)
        name = "Welch's T"
        name_formatted = "Welch's T"
    end
    
    properties
        t
        ss_t
    end
    
    methods
        function obj = WelchT(size)
            import nla.* % required due to matlab package system quirks
            % Superclass constructor
            obj@nla.net.BaseCorrResult(size);
            
            obj.t = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function prob = withinNetPairOneNet(obj, coeff_net, coeff_net_perm)
            [~, prob, ~, ~] = ttest2(coeff_net, coeff_net_perm, 'Vartype', 'unequal');
        end
        
        function table_new = genSummaryTable(obj, table_old)
            import nla.* % required due to matlab package system quirks
            table_new = [genSummaryTable@nla.net.BasePermResult(obj, table_old), table(obj.t.v, 'VariableNames', [obj.name])];
        end
    end
end
