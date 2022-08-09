classdef WelchT < nla.net.BaseCorrResult
    %WELCHT The output result of a NetLevelWelchTTest
    
    properties (Constant)
        name = "Welch's T"
        name_formatted = "Welch's T"
    end
    
    properties
        t
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
    end
end
