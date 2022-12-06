function checkHeadMotion(fig, input_struct, motion)
    import nla.* % required due to matlab package system quirks
    
    prog = uiprogressdlg(fig, 'Title', 'Generating figures', 'Message', 'Generating head motion figures');
    prog.Value = 0.02;
    distances = helpers.euclidianDistanceROIs(input_struct.net_atlas);
    prog.Value = 0.75;
    [r_vec, p_vec] = corr(motion, input_struct.func_conn.v', 'type', 'Pearson');
    
    prob = nla.TriMatrix(input_struct.net_atlas.numROIs());
    r = nla.TriMatrix(input_struct.net_atlas.numROIs());
    prob.v = p_vec';
    r.v = r_vec';
    
    prog.Value = 0.98;
    
    %% Visualization of head motion on brain
    color_scale = 1000;
    color_map = parula(color_scale);
    mesh_alpha = 0.5;
    ROI_radius = 4;
    ctx = gfx.MeshType.STD;
    llimit = -1;
    ulimit = 1;
    
    gfx.createFigure(1550, 500);

    ax = subplot('Position',[0.075,0.1,0.25,0.8]);
    title(ax, sprintf("Edges significantly (p < 0.05) related to motion\n"));
    gfx.drawROIsOnCortex(ax, input_struct.net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.DORSAL, false, gfx.BrainColorMode.NONE);
    
    for col = 1:input_struct.net_atlas.numROIs()
        for row = (col + 1):input_struct.net_atlas.numROIs()
            if prob.get(row, col) < 0.05
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
    ax = subplot('Position',[0.38,0.15,0.25,0.75]);
    title(ax, "FC-Motion Correlation Histogram");
    histogram(ax, r_vec, 'EdgeColor', 'black', 'FaceColor', 'black');
    xlabel(ax, 'FC-Motion Correlation (Pearson r)');
    
    %% Heatmap of corr/distance
    ax = subplot('Position',[0.71,0.15,0.25,0.75]);
    title(ax, "FC-Motion Correlation vs. ROI Distance");
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
    
    close(prog);
end

