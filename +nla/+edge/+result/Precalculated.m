classdef Precalculated < nla.edge.result.Base
    %SIMULATED The output result of a Simulated edge-level result
    
    methods
        function obj = Precalculated(size, prob_max)
            import nla.* % required due to matlab package system quirks
            % hack because superclass constructor can't be optional??
            if nargin == 0
                size = 2;
                prob_max = -1;
            end
            
            % Superclass constructor
            obj@nla.edge.result.Base(size, prob_max);
        end
    end
end
