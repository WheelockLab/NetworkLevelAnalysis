function drawBrainVis(edge_input_struct, input_struct, net_atlas, ctx, mesh_alpha, ROI_radius, surface_parcels, edge_result, net1, net2, sig_based)
    import nla.* % required due to matlab package system quirks
    
    color_fc = true;
    
    %% Display figures 
    fig = gfx.createFigure(1550, 750);
    fig.Name = sprintf('Brain Visualization: Average of edge-level correlations between nets in [%s - %s] Network Pair', net_atlas.nets(net1).name, net_atlas.nets(net2).name);
    
    llimit = edge_result.coeff_range(1);
    ulimit = edge_result.coeff_range(2);
    
    color_map = turbo();
    color_map_n = hsv(2800);
    color_map_n = color_map_n(1401:2400,:);
    color_map_p = cat(1, summer(500), flip(autumn(500), 1));
    
    ROI_vals = nan(net_atlas.numROIs(), 1);
    fc_vals = nan(net_atlas.numROIs(), 1);
	net1_ROI_indexes = net_atlas.nets(net1).indexes;
    net2_ROI_indexes = net_atlas.nets(net2).indexes;
    
    function [coeff1, coeff2, fc1, fc2] = get_coeffs(n1, n2)
        coeff1 = edge_result.coeff.get(n1, n2);
        coeff2 = edge_result.coeff.get(n2, n1);
        fc1 = mean(edge_input_struct.func_conn.get(n1, n2), 2);
        fc2 = mean(edge_input_struct.func_conn.get(n2, n1), 2);
        
        if sig_based
            prob_sig1 = edge_result.prob_sig.get(n1, n2);
            prob_sig2 = edge_result.prob_sig.get(n2, n1);
            
            coeff1 = coeff1(logical(prob_sig1));
            coeff2 = coeff2(logical(prob_sig2));
            fc1 = fc1(logical(prob_sig1));
            fc2 = fc2(logical(prob_sig2));
        end
    end
    
    for ROI_idx_iter = 1:numel(net1_ROI_indexes)
        ROI_idx = net1_ROI_indexes(ROI_idx_iter);
        [c1, c2, fc1, fc2] = get_coeffs(ROI_idx, net2_ROI_indexes);
        ROI_vals(ROI_idx) = (sum(c1) + sum(c2)) / (numel(c1) + numel(c2));
        fc_vals(ROI_idx) = (sum(fc1) + sum(fc2)) / (numel(fc1) + numel(fc2));
    end
    
    for ROI_idx_iter = 1:numel(net2_ROI_indexes)
        ROI_idx = net2_ROI_indexes(ROI_idx_iter);
        [c1, c2, fc1, fc2] = get_coeffs(ROI_idx, net1_ROI_indexes);
        ROI_val = (sum(c1) + sum(c2)) / (numel(c1) + numel(c2));
        fc_val = (sum(fc1) + sum(fc2)) / (numel(fc1) + numel(fc2));
        if net1 == net2
            ROI_vals(ROI_idx) = (ROI_vals(ROI_idx) + ROI_val) ./ 2;
            fc_vals(ROI_idx) = (fc_vals(ROI_idx) + fc_val) ./ 2;
        else
            ROI_vals(ROI_idx) = ROI_val;
            fc_vals(ROI_idx) = fc_val;
        end
    end

    function cols = valsToColor(ROI_vals, fc_vals, color_map, color_map_p, color_map_n, color_fc, llimit, ulimit)
        if color_fc
            ROI_vals_indexed_p = int32(helpers.normClipped(fc_vals, -0.5, 0.5) * size(color_map_p, 1));
            ROI_vals_indexed_n = int32(helpers.normClipped(fc_vals, -0.5, 0.5) * size(color_map_n, 1));
            cols_p = ind2rgb(ROI_vals_indexed_p, color_map_p);
            cols_n = ind2rgb(ROI_vals_indexed_n, color_map_n);
            cols(ROI_vals > 0, :) = cols_p(ROI_vals > 0, :);
            cols(ROI_vals <= 0, :) = cols_n(ROI_vals <= 0, :);
            % TODO WIP TEST THIS
        else
            color_scale = size(color_map, 1);
            ROI_vals_indexed = int32(helpers.normClipped(ROI_vals, llimit, ulimit) * color_scale);
            cols = ind2rgb(ROI_vals_indexed, color_map);
        end
    end
    
    % map colors to limits

    color_mat = valsToColor(ROI_vals, fc_vals, color_map, color_map_p, color_map_n, color_fc, llimit, ulimit);
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
                    fc_val = mean(edge_input_struct.func_conn.get(b, a));
                else
                    val = edge_result.coeff.get(a, b);
                    fc_val = mean(edge_input_struct.func_conn.get(a, b));
                end
                if ~isempty(val)
                    col = valsToColor(val, fc_val, color_map, color_map_p, color_map_n, color_fc, llimit, ulimit);
                    col = [reshape(col, [1, 3]), 0.5];
                    p = plot3([ROI_pos(a, 1), ROI_pos(b, 1)], [ROI_pos(a, 2), ROI_pos(b, 2)], [ROI_pos(a, 3), ROI_pos(b, 3)], 'Color', col, 'LineWidth', 5);
                    p.Annotation.LegendInformation.IconDisplayStyle = 'off';
                end
            end
        end
    end

    
    if surface_parcels && ~islogical(net_atlas.parcels)
        ax = subplot('Position',[.45,0.505,.53,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, 1, ROI_radius, gfx.ViewPos.LAT, surface_parcels, gfx.BrainColorMode.COLOR_ROIS, color_mat);
        drawROISpheres(ROI_final_pos);
        
        ax = subplot('Position',[.45,0.055,.53,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, 1, ROI_radius, gfx.ViewPos.MED, surface_parcels, gfx.BrainColorMode.COLOR_ROIS, color_mat);
        drawROISpheres(ROI_final_pos);
    else
        ax = subplot('Position',[.45,0.505,.26,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.BACK, surface_parcels, gfx.BrainColorMode.NONE);
        drawROISpheres(ROI_final_pos);
        drawEdges(ROI_final_pos);
        
        ax = subplot('Position',[.73,0.505,.26,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.FRONT, surface_parcels, gfx.BrainColorMode.NONE);
        drawROISpheres(ROI_final_pos);
        drawEdges(ROI_final_pos);
        
        ax = subplot('Position',[.45,0.055,.26,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.LEFT, surface_parcels, gfx.BrainColorMode.NONE);
        drawROISpheres(ROI_final_pos);
        drawEdges(ROI_final_pos);
        
        ax = subplot('Position',[.73,0.055,.26,.45]);
        ROI_final_pos = gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.RIGHT, surface_parcels, gfx.BrainColorMode.NONE);
        drawROISpheres(ROI_final_pos);
        drawEdges(ROI_final_pos);
    end
    
    if color_fc
        ax = subplot('Position',[.075,0.175,.35,.75]);
    else
        ax = subplot('Position',[.075,0.025,.35,.9]);
    end
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
    if color_fc
        colorbar_ax = subplot('Position',[.02,0,0.4,0.1]);
        colorbar_image = imread('+nla/+gfx/+images/brain_vis_fc_colormap.png');
        dims = size(colorbar_image);
        image(colorbar_ax, colorbar_image);
        gfx.hideAxes(colorbar_ax);
        colorbar_ax.Units = 'pixels';
        colorbar_ax.Position(3:4) = [dims(2), dims(1)];
    else
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
end