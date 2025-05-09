function drawConvergenceMap(edge_input_struct, input_struct, net_atlas, sig_count_mat, num_tests, names, edge_result, color_map)
    %DRAWCONVERGENCEMAP View convergence map (chord plot summarizing many
    %results)
    %   edge_input_struct: edge-level input struct
    %   input_struct: net-level input struct
    %   net_atlas: relevant NetworkAtlas object
    %   sig_count_mat: NnetsxNnets TriMatrix where each element's value is
    %       the number of tests which ranked that net-pair significant
    %   num_tests: total number of tests performed
    %   names: cell array of the names of each test
    %   edge_result: edge-level result
    %   color_map: color map of convergence map
    
    import nla.TriMatrix nla.TriMatrixDiag

    ax_width = 750;
    trimat_width = 500;
    bottom_text_height = 250;
    
    fig = nla.gfx.createFigure(ax_width + trimat_width, ax_width);
    fig.Renderer = 'painters';
    
    %% Chord plot
    
    ax = axes(fig, 'Units', 'pixels', 'Position', [trimat_width, 0, ax_width, ax_width]);
    nla.gfx.hideAxes(ax);
    
    sig_mat = TriMatrix(net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
    sig_mat.v = sig_count_mat.v ./ num_tests;
    
    chord_plotter = nla.gfx.chord.ChordPlot(net_atlas, ax, 500, sig_mat, 'color_map', color_map);
    chord_plotter.drawChords();
    
    %% Trimatrix plot
    function brainFigsButtonClickedCallback(net1, net2)
        f = waitbar(0.05, sprintf('Generating %s - %s net-pair brain plot', net_atlas.nets(net1).name,...
            net_atlas.nets(net2).name));
        nla.gfx.drawBrainVis(edge_input_struct, input_struct, net_atlas, nla.gfx.MeshType.STD, 0.25, 3,...
            true, edge_result, net1, net2, false);
        waitbar(0.95);
        close(f)
    end
    matrix_plot = nla.gfx.plots.MatrixPlot(fig, sprintf('Convergence map\nSignificant Tests Per Net-Pair'),...
        sig_count_mat, net_atlas.nets, nla.gfx.FigSize.SMALL,'y_position', bottom_text_height,...
        'lower_limit', 0, 'upper_limit', num_tests, 'discrete_colorbar', true,...
        'network_clicked_callback', @brainFigsButtonClickedCallback, 'draw_legend', false, 'color_map', color_map);
    matrix_plot.displayImage();

    %% Plot names
    text_ax = axes(fig, 'Units', 'pixels', 'Position', [55, bottom_text_height + 15, 450, 75]);
    nla.gfx.hideAxes(text_ax);
    text(text_ax, 0, 0,...
        sprintf("Click any net-pair in the above plot to view its edge-level correlations.\n\nMethods/Tests used:") + newline + join(names, newline),...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
end