classdef Network < handle & nla.interfaces.IndexGroup
    %NETWORK Network meta-information and contained regions of interest
    
    properties
        name
        color
        indexes % indexes of ROIs(regions of interest) that make up the network
    end
    
    methods
        function obj = Network(name, color, indexes)
            % Matlab doesn't support multiple constructors
            if nargin ~= 0
                obj.name = name;
                obj.color = color;
                obj.indexes = uint32(indexes(:));
            end
        end
        
        function addROI(obj, new_ROI)
            obj.indexes = [obj.indexes; new_ROI];
        end
        
        function n = numROIs(obj)
            n = numel(obj.indexes);
        end
    end
end

