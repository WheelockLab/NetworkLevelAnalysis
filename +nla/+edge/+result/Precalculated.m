classdef Precalculated < nla.edge.result.Base
    %SIMULATED The output result of a Simulated edge-level result
    
    methods
        function obj = Precalculated(size, prob_max)
            if nargin == 0
                size = 2;
                prob_max = -1;
            end
            
            % Superclass constructor
            obj@nla.edge.result.Base(size, prob_max);
        end
    end
end
