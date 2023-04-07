classdef Simulated < nla.edge.result.Base
    %SIMULATED The output result of a Simulated edge-level result
    
    methods
        function obj = Simulated(size, prob_max)
            import nla.* % required due to matlab package system quirks
            % hack because superclass constructor can't be optional??
            if nargin == 0
                size = 2;
                prob_max = -1;
            end
            
            % Superclass constructor
            obj@nla.edge.result.Base(size, prob_max);
            
            if nargin ~= 0
                obj.coeff_range = [-2 2];
            end
        end
        
        function output(obj, net_atlas, flags)
             output@nla.edge.result.Base(obj, net_atlas, flags, 'Edge-level Significance (z(P) >= 2)');
        end
    end
end
