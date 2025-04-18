function ROI_final_pos = drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, view_pos, surface_parcels, color_mode, color_mat)
    %DRAWROISONCORTEX Draw ROIs on cortex mesh
    %   net_atlas: relevant NetworkAtlas object
    %   ctx: MeshType object determining what mesh inflation value to use
    %   mesh_alpha: transparency of cortex mesh, 0-1
    %   ROI_radius: Radius to display ROI centroids as
    %   view_pos: ViewPos enumeration value, which direction to view cortex
    %   surface_parcels: Boolean value, whether to display surface parcels
    %       (if supported by network atlas) instead of ROI centroids
    %   color_mode: BrainColorMode enumeration value, whether you are
    %       providing per-network colors, per-ROI, etc.
    %   color_mat: Nx3 array of color values, where is is number of ROIs,
    %       networks, etc. depending on color_mode
    %   ROI_final_pos: Nx3 matrix of positions ROIs were displayed at
  
    import nla.gfx.BrainColorMode nla.gfx.drawCortex

    %% Calculate ROI locations
    [mesh_l, mesh_r] = nla.gfx.anatToMesh(net_atlas.anat, ctx, view_pos);
    ROI_pos = [net_atlas.ROIs.pos]';
    % find which node each ROI is nearest to
    [idx_l, dist_l] = knnsearch(net_atlas.anat.hemi_l.nodes, ROI_pos);
    [idx_r, dist_r] = knnsearch(net_atlas.anat.hemi_r.nodes, ROI_pos);
    for n = 1:net_atlas.numNets()
        for r = 1:numel(net_atlas.nets(n).indexes)
            ROI_idx = net_atlas.nets(n).indexes(r);
            offset = [NaN NaN NaN];
            if dist_l(ROI_idx) < dist_r(ROI_idx)
                offset = mesh_l(idx_l(ROI_idx), :) - net_atlas.anat.hemi_l.nodes(idx_l(ROI_idx), :);
            else
                offset = mesh_r(idx_r(ROI_idx), :) - net_atlas.anat.hemi_r.nodes(idx_r(ROI_idx), :);
            end
            % offset each ROI equally with its nearest node
            ROI_final_pos(ROI_idx, :) = ROI_pos(ROI_idx, :) + offset;
            
            if color_mode == BrainColorMode.DEFAULT_NETS
                ROI_color(ROI_idx, :) = net_atlas.nets(n).color;
            elseif color_mode == BrainColorMode.COLOR_NETS
                ROI_color(ROI_idx, :) = color_mat(n, :);
            elseif color_mode == BrainColorMode.COLOR_ROIS
                ROI_color(ROI_idx, :) = color_mat(ROI_idx, :);
            end
        end
    end
    
    %% Draw ROIs + cortex
    if color_mode ~= BrainColorMode.NONE &&...
        surface_parcels &&...
        ~islogical(net_atlas.parcels) &&...
        size(net_atlas.parcels.ctx_l, 1) == size(net_atlas.anat.hemi_l.nodes, 1) &&...
        size(net_atlas.parcels.ctx_r, 1) == size(net_atlas.anat.hemi_r.nodes, 1)
        
        % % Display cortex colored with each vertex's associated ROI color
        % Prepend the ROI color array with a 'zeroth' color, increment the
        % parcellization indices by one so this 'zeroth' color is used by
        % all parcels with an ROI index of zero (unassigned to ROI).
        ROI_color_with_missing = [0.5 0.5 0.5; ROI_color];
        drawCortex(ax, net_atlas.anat, ctx, mesh_alpha, view_pos, ROI_color_with_missing(net_atlas.parcels.ctx_l + 1, :),...
            ROI_color_with_missing(net_atlas.parcels.ctx_r + 1, :));
    else
        drawCortex(ax, net_atlas.anat, ctx, mesh_alpha, view_pos);
        if color_mode ~= BrainColorMode.NONE
            for i = 1:net_atlas.numROIs()
                % render a sphere at each ROI location
                nla.gfx.drawSphere(ax, ROI_final_pos(i, :), ROI_color(i, :), ROI_radius);
            end
        end
    end
    
    colorbar(ax, 'off');
    hold(ax, 'on');
end

