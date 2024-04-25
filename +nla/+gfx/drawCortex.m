function drawCortex(ax, anat, ctx, mesh_alpha, view_pos, color_l, color_r)
    %DRAWROISONCORTEX Draw ROIs on cortex mesh
    %   net_atlas: relevant NetworkAtlas object
    %   anat: struct containing various inflation values of cortex vertices
    %   ctx: MeshType object determining what mesh inflation value to use
    %   mesh_alpha: transparency of cortex mesh, 0-1
    %   view_pos: ViewPos enumeration value, which direction to view cortex

    import nla.gfx.ViewPos

    %% Default values
    if ~exist('color_l','var'), color_l = repmat(0.5, [size(anat.hemi_l.nodes, 1), 3]); end
    if ~exist('color_r','var'), color_r = repmat(0.5, [size(anat.hemi_r.nodes, 1), 3]); end

    %% Figure settings
    ax.Color = 'w';

    %% Image hemispheres
    % Re-position meshes for standard transverse orientation etc.
    [mesh_l, mesh_r] = nla.gfx.anatToMesh(anat, ctx, view_pos);

    % Set lighting and persepctive
    if view_pos == ViewPos.LAT || view_pos == ViewPos.MED
        view(ax, [-90,0]);
        light(ax, 'Position', [-100,200,0], 'Style', 'local');
        % These two lines create minimal lighting good luck. <-- what did he mean by this?
        light(ax, 'Position', [-50,-500,100], 'Style', 'infinite'); 
        light(ax, 'Position', [-50,0,0], 'Style', 'infinite');
    else
        if view_pos == ViewPos.POST
            view(ax, [0 0]);
        elseif view_pos == ViewPos.DORSAL
            view(ax, [0 90]);
            light(ax, 'Position', [100,300,100], 'Style', 'infinite');
        elseif view_pos == ViewPos.LEFT
            view(ax, [-90,0]);
            light(ax, 'Position', [-100,0,0], 'Style', 'infinite');
        elseif view_pos == ViewPos.RIGHT
            view(ax, [90,0]);
            light(ax, 'Position', [100,0,0], 'Style', 'infinite');
        elseif view_pos == ViewPos.FRONT
            view(ax, [180,0]);
            light(ax, 'Position', [100,300,100], 'Style', 'infinite');
        elseif view_pos == ViewPos.BACK
            view(ax, [0,0]);
            light(ax, 'Position', [0,-200,0], 'Style', 'infinite');
        end
        
        if view_pos == ViewPos.POST ||...
            view_pos == ViewPos.DORSAL ||...
            view_pos == ViewPos.LEFT ||...
            view_pos == ViewPos.RIGHT ||...
            view_pos == ViewPos.FRONT ||...
            view_pos == ViewPos.BACK
            light(ax, 'Position', [-500,-20,0], 'Style', 'local');
            light(ax, 'Position', [500,-20,0], 'Style', 'local');
            light(ax, 'Position', [0,-200,50], 'Style', 'local');
        end
    end
    
    nla.gfx.drawCortexHemi(ax, anat.hemi_l, mesh_l, color_l, mesh_alpha);
    nla.gfx.drawCortexHemi(ax, anat.hemi_r, mesh_r, color_r, mesh_alpha);

    axis(ax, 'image');
    axis(ax, 'off');
end

