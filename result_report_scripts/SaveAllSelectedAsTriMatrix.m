function SaveAllSelectedAsTriMatrix(inArg)

    fprintf('\nIn function!\n');
    
    plotter = nla.net.result.plot.PermutationTestPlotter(inArg.net_atlas);
    
    plot_parameters = struct();
    
    color_map = parula(1000);
%     statistic_matrix = parameters.statistic_plot_matrix;
%     p_value_max = parameters.p_value_plot_max;
%     plot_label = parameters.name_label;
%     significance_plot = parameters.significance_plot;
%     clickCallback = parameters.callback;
%     plot_scale = parameters.plot_scale;
    
    for i = 1:length(inArg.selected_results)
        thisFig = figure();
        %parameters.statistic_matrix = 
        %parameters.significance_plot = 
        %parameters.plot_label = 
        %plotter.plotProbability(thisFig, 
        
    end
    
    
    
    plotProbability(obj, plot_figure, parameters, x_coordinate, y_coordinate)
    
end