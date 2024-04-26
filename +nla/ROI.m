classdef ROI
    %ROI Region of interest in the brain
    %   Right now this class isn't so useful but in the future there could
    %   be more metadata associated with each region such as more detailed
    %   bounds, etc.
    
    properties
        pos
    end
    
    methods
        function obj = ROI(pos)
            obj.pos = pos;
        end
    end
end

