function drawROIsOnCortex(ax, net_atlas, anat, ctx, mesh_alpha, ROI_radius, view_pos, surface_parcels)
    import nla.* % required due to matlab package system quirks
    %% Calculate ROI locations
    [mesh_l, mesh_r] = gfx.anatToMesh(anat, ctx, view_pos);
    ROI_pos = [net_atlas.ROIs.pos]';
    % find which node each ROI is nearest to
    [idx_l, dist_l] = knnsearch(anat.hemi_l.nodes, ROI_pos);
    [idx_r, dist_r] = knnsearch(anat.hemi_r.nodes, ROI_pos);
    for n = 1:net_atlas.numNets()
        for r = 1:numel(net_atlas.nets(n).indexes)
            ROI_idx = net_atlas.nets(n).indexes(r);
            offset = [NaN NaN NaN];
            if dist_l(ROI_idx) < dist_r(ROI_idx)
                offset = mesh_l(idx_l(ROI_idx), :) - anat.hemi_l.nodes(idx_l(ROI_idx), :);
            else
                offset = mesh_r(idx_r(ROI_idx), :) - anat.hemi_r.nodes(idx_r(ROI_idx), :);
            end
            % offset each ROI equally with its nearest node
            ROI_final_pos(ROI_idx, :) = ROI_pos(ROI_idx, :) + offset;
            ROI_color(ROI_idx, :) = net_atlas.nets(n).color;
        end
    end
    
    %% Draw ROIs + cortex
    if surface_parcels && ~islogical(net_atlas.parcels) && size(net_atlas.parcels.ctx_l, 1) == size(anat.hemi_l.nodes, 1) && size(net_atlas.parcels.ctx_r, 1) == size(anat.hemi_r.nodes, 1)
        %% Display cortex colored with each vertex's associated ROI color
        % Prepend the ROI color array with a 'zeroth' color, increment the
        % parcellization indices by one so this 'zeroth' color is used by
        % all parcels with an ROI index of zero (unassigned to ROI).
        ROI_color_with_missing = [0.5 0.5 0.5; ROI_color];
        gfx.drawCortex(ax, anat, ctx, mesh_alpha, view_pos, ROI_color_with_missing(net_atlas.parcels.ctx_l + 1, :), ROI_color_with_missing(net_atlas.parcels.ctx_r + 1, :));
    else
        gfx.drawCortex(ax, anat, ctx, mesh_alpha, view_pos);
        for i = 1:net_atlas.numROIs()
            % render a sphere at each ROI location
            gfx.drawSphere(ax, ROI_final_pos(i, :), ROI_color(i, :), ROI_radius);
        end
    end
    
    colorbar(ax, 'off');
    hold(ax, 'on');
end

