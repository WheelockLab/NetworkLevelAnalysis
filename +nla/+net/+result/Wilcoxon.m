classdef Wilcoxon < nla.net.BaseCorrResult
    %WILCOXONRESULT The output result of a WilcoxonTest
    
    properties (Constant)
        name = "Wilcoxon"
        name_formatted = "Wilcoxon"
    end
    
    properties
        w
        z
    end
    
    methods
        function obj = Wilcoxon(size)
            import nla.* % required due to matlab package system quirks
            % Superclass constructor
            obj@nla.net.BaseCorrResult(size);
            
            obj.w = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function prob = withinNetPairOneNet(obj, coeff_net, coeff_net_perm)
            [prob, ~, ~] = ranksum(coeff_net, coeff_net_perm);
        end
        
        function table_new = genSummaryTable(obj, table_old)
            import nla.* % required due to matlab package system quirks
            table_new = [genSummaryTable@nla.net.BasePermResult(obj, table_old), table(obj.w.v, 'VariableNames', [obj.name]), table(obj.z.v, 'VariableNames', [obj.name + " Z-score"])];
        end
    end
end
