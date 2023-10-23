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
    import nla.* % required due to matlab package system quirks
    
    ax_width = 750;
    trimat_width = 500;
    bottom_text_height = 250;
    
    fig = gfx.createFigure(ax_width + trimat_width, ax_width);
    fig.Renderer = 'painters';
    
    %% Chord plot
    
    ax = axes(fig, 'Units', 'pixels', 'Position', [trimat_width, 0, ax_width, ax_width]);
    gfx.hideAxes(ax);
    
    sig_mat = TriMatrix(net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
    sig_mat.v = sig_count_mat.v ./ num_tests;
    
    gfx.drawChord(ax, 500, net_atlas, sig_mat, color_map);
    
    %% Trimatrix plot
    function brainFigsButtonClickedCallback(net1, net2)
        f = waitbar(0.05, sprintf('Generating %s - %s net-pair brain plot', net_atlas.nets(net1).name, net_atlas.nets(net2).name));
        gfx.drawBrainVis(edge_input_struct, input_struct, net_atlas, gfx.MeshType.STD, 0.25, 3, true, edge_result, net1, net2, false);
        waitbar(0.95);
        close(f)
    end
%     gfx.drawMatrixOrg(fig, 0, bottom_text_height, sprintf('Convergence map\nSignificant Tests Per Net-Pair'), sig_count_mat, 0, num_tests, net_atlas.nets, gfx.FigSize.SMALL, gfx.FigMargins.WHITESPACE, false, true, color_map, false, true, @brainFigsButtonClickedCallback);
    matrix_plot = gfx.matrix.MatrixPlot(fig, sprintf('Convergence map\nSignificant Tests Per Net-Pair'), sig_count_mat, net_atlas.nets, gfx.FigSize.SMALL, @brainFigsButtonClickedCallback, false, gfx.FigMargins.WHITESPACE, false, true, color_map);
    matrix_plot.y_position = bottom_text_height;
    matrix_plot.lower_limit = 0;
    matrix_plot.upper_limit = num_tests;
    matrix_plot.discrete_colorbar = true;
    matrix_plot.displayImage();

    %% Plot names
    text_ax = axes(fig, 'Units', 'pixels', 'Position', [55, bottom_text_height + 15, 450, 75]);
    gfx.hideAxes(text_ax);
    text(text_ax, 0, 0, sprintf("Click any net-pair in the above plot to view its edge-level correlations.\n\nMethods/Tests used:") + newline + join(names, newline), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
end