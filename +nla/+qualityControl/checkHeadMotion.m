function checkHeadMotion(fig, input_struct, motion)
    import nla.* % required due to matlab package system quirks
    
    prog = uiprogressdlg(fig, 'Title', 'Generating figures', 'Message', 'Generating head motion figures');
    prog.Value = 0.02;
    distances = helpers.euclidianDistanceROIs(input_struct.net_atlas);
    prog.Value = 0.75;
    [r_vec, p_vec] = corr(motion, input_struct.func_conn.v', 'type', 'Pearson');
    
    prob = nla.TriMatrix(input_struct.net_atlas.numROIs());
    r = nla.TriMatrix(input_struct.net_atlas.numROIs());
    h = nla.TriMatrix(input_struct.net_atlas.numROIs(), 'logical');
    prob.v = p_vec';
    r.v = r_vec';
    h.v = lib.fdr_bh(prob.v);
    
    prog.Value = 0.98;
    
    %% Visualization of head motion on brain
    color_scale = 1000;
    color_map = turbo(color_scale);
    mesh_alpha = 0.5;
    ROI_radius = 4;
    ctx = gfx.MeshType.STD;
    llimit = -0.3;
    ulimit = 0.3;
    
    fig = gfx.createFigure(1800, 900);
    [width, height] = gfx.drawMatrixOrg(fig, 0, 0, "FC-motion correlation (Pearson's r)", r, llimit, ulimit, input_struct.net_atlas.nets, gfx.FigSize.LARGE, gfx.FigMargins.WHITESPACE, true, true);
    fig.Position(3) = width * 2;
    fig.Position(4) = height;

    ax = subplot('Position', [0.780, 0.540, 0.20, 0.40]);
    setTitle(ax, sprintf("FC-motion correlation (Pearson's r) (q < 0.05)\n"));
    gfx.drawROIsOnCortex(ax, input_struct.net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.DORSAL, false, gfx.BrainColorMode.NONE);
    
    for col = 1:input_struct.net_atlas.numROIs()
        for row = (col + 1):input_struct.net_atlas.numROIs()
            if h.get(row, col)
                pos1 = input_struct.net_atlas.ROIs(row).pos;
                pos2 = input_struct.net_atlas.ROIs(col).pos;
                
                edge_val_indexed = int32(helpers.normClipped(r.get(row, col), llimit, ulimit) * color_scale);
                edge_color = ind2rgb(edge_val_indexed, color_map);
                
                p = plot3([pos1(1), pos2(1)], [pos1(2), pos2(2)], [pos1(3), pos2(3)], 'Color', edge_color, 'LineWidth', 2);
                p.Annotation.LegendInformation.IconDisplayStyle = 'off';
            end
        end
    end
    
    light('Position',[0,100,100],'Style','local');
    
    num_ticks = 10;
    colormap(ax, color_map);
    cb = colorbar(ax);

    ticks = [0:num_ticks];
    cb.Ticks = double(ticks) ./ num_ticks;

    % tick labels
    labels = {};
    for i = ticks
        labels{i + 1} = sprintf("%.2g", llimit + (i * ((double(ulimit - llimit) / num_ticks))));
    end
    cb.TickLabels = labels;
    caxis(ax, [0, 1]);
    
    %% Distribution of corr
    ax = subplot('Position', [0.525, 0.075, 0.1875, 0.425]);
    setTitle(ax, "FC-Motion Correlation Histogram");
    histogram(ax, r_vec, 'EdgeColor', 'black', 'FaceColor', 'black');
    xlabel(ax, 'FC-Motion Correlation (Pearson r)');
    
    %% Heatmap of corr/distance
    ax = subplot('Position', [0.755, 0.075, 0.225, 0.425]);
    setTitle(ax, "FC-Motion Correlation vs. ROI Distance");
    [values, centers] = hist3([distances.v, r_vec'], [50, 50]);
    imagesc(ax, centers{:}, values');
    xlabel(ax, 'Euclidian Distance');
    ylabel(ax, 'FC-Motion Correlation (Pearson r)');
    colorbar(ax);
    axis(ax, 'xy');
    
    % Least-squares regression line
    lsline_coeff = polyfit(distances.v, r_vec', 1);
    lsline_x = linspace(ax.XLim(1), ax.XLim(2), 2);
    lsline_y = polyval(lsline_coeff, lsline_x);
    hold('on');
    plot(lsline_x, lsline_y, 'r');
    
    %% Summary statistics
    percent_sig = (sum(h.v) ./ numel(h.v)) * 100;
    med_abs_corr = median(abs(r.v));
    fc_motion_distance_corr = corr(r.v, distances.v);
    
    ax = subplot('Position', [0.525, 0.95, 0.1875, 0.40]);
    gfx.hideAxes(ax);
    text(ax, 0, 0, sprintf("Percent of significant edges: %0.2f%%\nMedian absolute correlation: %0.2f\nFC-motion-distance correlation: %0.2f", percent_sig, med_abs_corr, fc_motion_distance_corr), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    
    close(prog);
end

