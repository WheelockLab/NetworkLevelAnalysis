function drawConvergenceMap(net_atlas, sig_count_mat, num_tests, names, edge_result, color_map)
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
        gfx.drawBrainVis(net_atlas, gfx.MeshType.STD, 0.25, 3, true, edge_result, net1, net2);
    end
    gfx.drawMatrixOrg(fig, 0, bottom_text_height, sprintf('Convergence map\nSignificant Tests Per Net-Pair'), sig_count_mat, 0, num_tests, net_atlas.nets, gfx.FigSize.SMALL, gfx.FigMargins.WHITESPACE, false, true, color_map, false, true, @brainFigsButtonClickedCallback);

    %% Plot names
    text_ax = axes(fig, 'Units', 'pixels', 'Position', [55, bottom_text_height + 15, 450, 75]);
    gfx.hideAxes(text_ax);
    text(text_ax, 0, 0, sprintf("Click any net-pair in the above plot to view its edge-level correlations.\n\nMethods/Tests used:") + newline + join(names, newline), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
end