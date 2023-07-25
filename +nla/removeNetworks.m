function [atlas_out, fc_out] = removeNetworks(atlas_in, nets, name, fc_in)
    %REMOVENETWORKS Remove given networks from a network atlas
    %	atlas_in: Input network atlas
    %	nets: Networks to remove
    %	name: Name of modified atlas
    %	(Optional) fc_in: Functional connectivity to remove given networks from
    %       as well
    net_mask = true(numel(atlas_in.net_names), 1);
    net_mask(nets) = false;
    
    atlas_out = struct();
    atlas_out.name = name;
    atlas_out.net_colors = atlas_in.net_colors(net_mask, :);
    atlas_out.net_names = {atlas_in.net_names{net_mask}}';
    atlas_out.space = atlas_in.space;
    
    ROI_mask = true(numel(atlas_in.ROI_order), 1);
    for i = 1:numel(nets)
        ROI_mask(atlas_in.ROI_key(:, 2) == nets(i)) = false;
    end
    
    net_remap = zeros(numel(net_mask), 1);
    net_num = 1;
    for i = 1:numel(net_remap)
        if sum(nets == i) == 0
            net_remap(i) = net_num;
            net_num = net_num + 1;
        end
    end
    
    atlas_out.ROI_pos = atlas_in.ROI_pos(ROI_mask, :);
    atlas_out.ROI_key = atlas_in.ROI_key(ROI_mask, :);
    atlas_out.ROI_key(:, 1) = [1:size(atlas_out.ROI_key, 1)];
    for i = 1:numel(net_remap)
        atlas_out.ROI_key(atlas_out.ROI_key(:, 2) == i, 2) = net_remap(i);
    end
    
    ROI_remap = zeros(numel(ROI_mask), 1);
    ROI_num = 1;
    for i = 1:numel(ROI_remap)
        if sum(nets == atlas_in.ROI_key(i, 2)) == 0
            ROI_remap(i) = ROI_num;
            ROI_num = ROI_num + 1;
        end
    end
    
    atlas_out.ROI_order = zeros(numel(ROI_remap), 1);
    for i = 1:numel(ROI_remap)
        atlas_out.ROI_order(i) = ROI_remap(atlas_in.ROI_order(i));
    end
    atlas_out.ROI_order = atlas_out.ROI_order(atlas_out.ROI_order ~=0);
    
    if isfield(atlas_in, 'parcels')
        ROI_inverse_order_map(atlas_in.ROI_order) = [1:numel(atlas_in.ROI_order)];
        ROI_inverse_order_map_with_missing = [0; ROI_inverse_order_map'];
        
        atlas_out.parcels = struct();
        atlas_out.parcels.ctx_l = ROI_inverse_order_map_with_missing(atlas_in.parcels.ctx_l + 1);
        atlas_out.parcels.ctx_r = ROI_inverse_order_map_with_missing(atlas_in.parcels.ctx_r + 1);

        ROI_remap_with_zero = [0; ROI_remap];
        atlas_out.parcels.ctx_l = ROI_remap_with_zero(atlas_out.parcels.ctx_l + 1);
        atlas_out.parcels.ctx_r = ROI_remap_with_zero(atlas_out.parcels.ctx_r + 1);
        
        ROI_order_with_zero = [0; atlas_out.ROI_order];
        atlas_out.parcels.ctx_l = ROI_order_with_zero(atlas_out.parcels.ctx_l + 1);
        atlas_out.parcels.ctx_r = ROI_order_with_zero(atlas_out.parcels.ctx_r + 1);
    end
    
    %% Functional connectivity (optional)
    if exist('fc_in', 'var')
        fc_ordered = fc_in(atlas_in.ROI_order, atlas_in.ROI_order, :);
        fc_reduced = fc_ordered(ROI_mask, ROI_mask, :);
        ROI_order_inverse(atlas_out.ROI_order) = [1:numel(atlas_out.ROI_order)]';
        fc_out = fc_reduced(ROI_order_inverse, ROI_order_inverse, :);
    end
end

