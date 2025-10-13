classdef OrdinaryLeastSquares < nla.edge.test.SandwichEstimator
        
    
    methods
        %Hacky way to change name and coeff_name in superclass is to change
        %properties in constructor
        function obj = OrdinaryLeastSquares()
            
            obj = obj@nla.edge.test.SandwichEstimator();
            obj.name = "Ordinary Least Squares";
            obj.coeff_name = "Contrast T -value";
        end
        
    end
    
    methods (Static)        
        function inputs = requiredInputs()
            inputs = {nla.inputField.Number('prob_max', 'Edge-level P threshold <', 0, 0.05, 1),...
                nla.inputField.NetworkAtlasFuncConn(), nla.inputField.OrdinaryLeastSquares()};
        end
    end
end