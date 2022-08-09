classdef (Abstract) IndexGroup < handle
    %INDEXGROUP Abstract class for passing to UI interfaces
    
    properties (Abstract)
        name
        color
        indexes
    end
end

