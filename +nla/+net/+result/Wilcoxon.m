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
    end
end
