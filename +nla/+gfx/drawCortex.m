function drawCortex(ax, anat, ctx, mesh_alpha, view_pos, color_l, color_r)
    import nla.* % required due to matlab package system quirks
    %% Default values
    if ~exist('color_l','var'), color_l = repmat(0.5, [size(anat.hemi_l.nodes, 1), 3]); end
    if ~exist('color_r','var'), color_r = repmat(0.5, [size(anat.hemi_r.nodes, 1), 3]); end

    %% Figure settings
    ax.Color = 'w';

    %% Image hemispheres
    % Re-position meshes for standard transverse orientation etc.
    [mesh_l, mesh_r] = gfx.anatToMesh(anat, ctx, view_pos);

    % Set lighting and persepctive
    if view_pos == gfx.ViewPos.LAT || view_pos == gfx.ViewPos.MED
        view(ax, [-90,0]);
        light(ax, 'Position', [-100,200,0], 'Style', 'local');
        light(ax, 'Position', [-50,-500,100], 'Style', 'infinite'); % These two lines create minimal lighting good luck. <-- what did he mean by this?
        light(ax, 'Position', [-50,0,0], 'Style', 'infinite');
    else
        if view_pos == gfx.ViewPos.POST
            view(ax, [0 0]);
        elseif view_pos == gfx.ViewPos.DORSAL
            view(ax, [0 90]);
            light(ax, 'Position', [100,300,100], 'Style', 'infinite');
        elseif view_pos == gfx.ViewPos.LEFT
            view(ax, [-90,0]);
            light(ax, 'Position', [-100,0,0], 'Style', 'infinite');
        elseif view_pos == gfx.ViewPos.RIGHT
            view(ax, [90,0]);
            light(ax, 'Position', [100,0,0], 'Style', 'infinite');
        elseif view_pos == gfx.ViewPos.FRONT
            view(ax, [180,0]);
            light(ax, 'Position', [100,300,100], 'Style', 'infinite');
        elseif view_pos == gfx.ViewPos.BACK
            view(ax, [0,0]);
            light(ax, 'Position', [0,-200,0], 'Style', 'infinite');
        end
        
        if view_pos == gfx.ViewPos.POST || view_pos == gfx.ViewPos.DORSAL || view_pos == gfx.ViewPos.LEFT || view_pos == gfx.ViewPos.RIGHT || view_pos == gfx.ViewPos.FRONT || view_pos == gfx.ViewPos.BACK
            light(ax, 'Position', [-500,-20,0], 'Style', 'local');
            light(ax, 'Position', [500,-20,0], 'Style', 'local');
            light(ax, 'Position', [0,-200,50], 'Style', 'local');
        end
    end
    
    gfx.drawCortexHemi(ax, anat.hemi_l, mesh_l, color_l, mesh_alpha);
    gfx.drawCortexHemi(ax, anat.hemi_r, mesh_r, color_r, mesh_alpha);

    axis(ax, 'image');
    axis(ax, 'off');
end

