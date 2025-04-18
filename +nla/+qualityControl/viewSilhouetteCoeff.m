function viewSilhouetteCoeff(fig, input_struct, remove_index)
    
    prog = uiprogressdlg(fig, 'Title', 'Generating figures', 'Message', 'Calculating silhouette coefficient');
    prog.Value = 0.02;
    
    %% Remove selected network (usually, the 'None'/unspecified network)
    plot_label = 'FC Average (Fisher Z(R))';
    keep_nets = true(input_struct.net_atlas.numNets(), 1);
    if remove_index ~= 0
        plot_label = [plot_label sprintf(' (''%s'' net removed)', input_struct.net_atlas.nets(remove_index).name)];
        keep_nets(remove_index) = false;
    end
    nets = input_struct.net_atlas.nets(keep_nets);

    %% Calculate average FC
    fc_avg = copy(input_struct.func_conn);
    fc_avg.v = mean(fc_avg.v, 2);
    
    prog.Value = 0.25;
    
    %% Calculate silhouette coefficients
    si_vals = nla.silhouetteCoeff(fc_avg, nets);
    
    prog.Value = 0.98;
    
    %% Display FC average plot with average silhouette value in label
    plot_label = [plot_label sprintf('\nMean silhouette value = %2.3f', mean(si_vals))];
    fig = nla.gfx.createFigure();
    matrix_plot = nla.gfx.plots.MatrixPlot(fig, plot_label, fc_avg, nets, nla.gfx.FigSize.LARGE);
    matrix_plot.displayImage();
    w = matrix_plot.image_dimensions("image_width");
    h = matrix_plot.image_dimensions("image_height");
    fig.Position(3) = w;
    fig.Position(4) = h;
    
    close(prog);
end