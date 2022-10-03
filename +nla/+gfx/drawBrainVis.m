function drawBrainVis(net_atlas, ctx, mesh_alpha, ROI_radius, surface_parcels, edge_result, net1, net2)
    import nla.* % required due to matlab package system quirks
    %% Display figures 
    fig = gfx.createFigure(1550, 750);
    fig.Name = sprintf('Brain Visualization: [%s - %s] Network Pair', net_atlas.nets(net1).name, net_atlas.nets(net2).name);
    
    llimit = edge_result.coeff_range(1);
    ulimit = edge_result.coeff_range(2);
    
    color_map = turbo();
    ROI_vals = nan(net_atlas.numROIs(), 1);
	net1_ROI_indexes = net_atlas.nets(net1).indexes;
    net2_ROI_indexes = net_atlas.nets(net2).indexes;
    for ROI_idx_iter = 1:numel(net1_ROI_indexes)
        ROI_idx = net1_ROI_indexes(ROI_idx_iter);
        ROI_sum = sum(edge_result.coeff.get(ROI_idx, net2_ROI_indexes)) + sum(edge_result.coeff.get(net2_ROI_indexes, ROI_idx));
        ROI_vals(ROI_idx) = ROI_sum / numel(net2_ROI_indexes);
    end
    for ROI_idx_iter = 1:numel(net2_ROI_indexes)
        ROI_idx = net2_ROI_indexes(ROI_idx_iter);
        ROI_sum = sum(edge_result.coeff.get(ROI_idx, net1_ROI_indexes)) + sum(edge_result.coeff.get(net1_ROI_indexes, ROI_idx));
        ROI_val = ROI_sum / numel(net1_ROI_indexes);
        if net1 == net2
            ROI_vals(ROI_idx) = (ROI_vals(ROI_idx) + ROI_val) ./ 2;
        else
            ROI_vals(ROI_idx) = ROI_val;
        end
    end

    % map colors to limits
    color_scale = size(color_map, 1);
    ROI_vals_indexed = int32(helpers.normClipped(ROI_vals, llimit, ulimit) * color_scale);
    color_mat = ind2rgb(ROI_vals_indexed, color_map);
    color_mat(isnan(ROI_vals), :) = 0.50;
    
    function drawROISpheres(ROI_pos)
        for n = [net1, net2]
            indexes = net_atlas.nets(n).indexes;
            for j_idx = 1:numel(indexes)
                j = indexes(j_idx);
                % render a sphere at each ROI location
                gfx.drawSphere(ax, ROI_pos(j, :), net_atlas.nets(n).color, ROI_radius);
            end
        end
    end

    function drawEdges(ROI_pos)
        a_indexes = net_atlas.nets(net1).indexes;
        b_indexes = net_atlas.nets(net2).indexes;
        for a_idx = 1:numel(a_indexes)
            a = a_indexes(a_idx);
            for b_idx = 1:numel(b_indexes)
                b = b_indexes(b_idx);
                if a < b
                    val = edge_result.coeff.get(b, a);
                else
                    val = edge_result.coeff.get(a, b);
                end
                if ~isempty(val)
                    val_indexed = int32(helpers.normClipped(val, llimit, ulimit) * color_scale);
                    col = ind2rgb(val_indexed, color_map);
                    col = [reshape(col, [1, 3]), 0.5];
                    p = plot3([ROI_pos(a, 1), ROI_pos(b, 1)], [ROI_pos(a, 2), ROI_pos(b, 2)], [ROI_pos(a, 3), ROI_pos(b, 3)], 'Color', col, 'LineWidth', 5);
                    p.Annotation.LegendInformation.IconDisplayStyle = 'off';
                end
            end
        end
    end

    
    if surface_parcels && ~islogical(net_atlas.parcels)
        ax = subplot('Position',[.45,0.455,.53,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, 1, ROI_radius, gfx.ViewPos.LAT, surface_parcels, gfx.BrainColorMode.COLOR_ROIS, color_mat);
        drawROISpheres(ROI_final_pos);
        
        ax = subplot('Position',[.45,0.005,.53,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, 1, ROI_radius, gfx.ViewPos.MED, surface_parcels, gfx.BrainColorMode.COLOR_ROIS, color_mat);
        drawROISpheres(ROI_final_pos);
    else
        ax = subplot('Position',[.45,0.455,.26,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.BACK, surface_parcels, gfx.BrainColorMode.NONE);
        drawROISpheres(ROI_final_pos);
        drawEdges(ROI_final_pos);
        
        ax = subplot('Position',[.73,0.455,.26,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.FRONT, surface_parcels, gfx.BrainColorMode.NONE);
        drawROISpheres(ROI_final_pos);
        drawEdges(ROI_final_pos);
        
        ax = subplot('Position',[.45,0.005,.26,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.LEFT, surface_parcels, gfx.BrainColorMode.NONE);
        drawROISpheres(ROI_final_pos);
        drawEdges(ROI_final_pos);
        
        ax = subplot('Position',[.73,0.005,.26,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.RIGHT, surface_parcels, gfx.BrainColorMode.NONE);
        drawROISpheres(ROI_final_pos);
        drawEdges(ROI_final_pos);
    end
    
    ax = subplot('Position',[.075,0.025,.35,.9]);
    if surface_parcels && ~islogical(net_atlas.parcels)
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, 1, ROI_radius, gfx.ViewPos.DORSAL, surface_parcels, gfx.BrainColorMode.COLOR_ROIS, color_mat);
        drawROISpheres(ROI_final_pos);
    else
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.DORSAL, surface_parcels, gfx.BrainColorMode.NONE);
        drawROISpheres(ROI_final_pos);
        drawEdges(ROI_final_pos);
    end
    
    light('Position',[0,100,100],'Style','local');
    
    %% Display legend
    hold(ax, 'on');
    if net1 == net2
        legend_entry = bar(ax, NaN);
        legend_entry.FaceColor = net_atlas.nets(net1).color;
        legend_entry.DisplayName = net_atlas.nets(net1).name;
    else
        for i = [net1, net2]
            legend_entry = bar(ax, NaN);
            legend_entry.FaceColor = net_atlas.nets(i).color;
            legend_entry.DisplayName = net_atlas.nets(i).name;
        end
    end
    hold(ax, 'off');
    legend(ax, 'Location', 'best');
    gfx.hideAxes(ax);
    
    %% Display colormap
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
end