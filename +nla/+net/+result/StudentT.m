classdef StudentT < nla.net.BaseCorrResult
    %STUDENTT The output result of a Net level Student's T-test
    
    properties (Constant)
        name = "Student's T"
        name_formatted = "Student's T"
    end
    
    properties
        t
    end
    
    methods
        function obj = StudentT(size)
            import nla.* % required due to matlab package system quirks
            % Superclass constructor
            obj@nla.net.BaseCorrResult(size);
            
            obj.t = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function prob = withinNetPairOneNet(obj, coeff_net, coeff_net_perm)
            [~, prob, ~, ~] = ttest2(coeff_net, coeff_net_perm);
        end
        
        function table_new = genSummaryTable(obj, table_old)
            import nla.* % required due to matlab package system quirks
            table_new = [genSummaryTable@nla.net.BasePermResult(obj, table_old), table(obj.t.v, 'VariableNames', [obj.name])];
        end
    end
end
