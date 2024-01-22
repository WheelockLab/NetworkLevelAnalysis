classdef WithinNetworkPairPlotter

    properties
        network_atlas
    end

    methods
        function obj = WithinNetworkPairPlotter(network_atlas)
            if nargin > 0
                obj.network_atlas = network_atlas;
            end
        end

        
    end

end