classdef WelchT < nla.edge.result.Base
    %WELCHT The output result of a WelchTTest
    
    properties
        dof
    end
    
    methods
        function obj = WelchT(size, prob_max, group_names)
            if nargin == 0
                size = 2;
                prob_max = -1;
            end
            
            % Superclass constructor
            obj@nla.edge.result.Base(size, prob_max);
            
            if nargin ~= 0
                obj.dof = nla.TriMatrix(size);
                obj.behavior_name = sprintf("%s > %s", group_names{1}, group_names{2});
                obj.coeff_range = [-3 3];
            end
        end
    end
end
