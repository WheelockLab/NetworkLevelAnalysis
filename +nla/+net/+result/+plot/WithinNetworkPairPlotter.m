classdef WithinNetworkPairPlotter < nla.net.result.plot.NoPermutationPlotter

    properties
        network_atlas
    end

    methods
        function obj = WithinNetworkPairPlotter(network_atlas)
            obj = obj@nla.net.result.plot.NoPermutationPlotter();
            if nargin > 0
                obj.network_atlas = network_atlas;
            end
        end
                
        function [w, h] = plotProbability(obj, plot_figure, parameters, x_coordinate, y_coordinate)
            % I know I don't need to define this here. I don't like it when the superclass methods just start showing up
            % Matlab's class organization is so hacked together, I just like to really show everything
            [w, h] = plotProbability@nla.net.result.plot.NoPermutationPlotter(obj, plot_figure, parameters, x_coordinate, y_coordinate);
        end
    end

end