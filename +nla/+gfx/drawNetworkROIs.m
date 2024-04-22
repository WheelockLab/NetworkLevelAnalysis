function drawNetworkROIs(net_atlas, ctx, mesh_alpha, ROI_radius, surface_parcels)
    %DRAWNETWORKROIS View ROIs on cortex mesh, colored by network, 3 views
    %   net_atlas: relevant NetworkAtlas object
    %   ctx: MeshType object determining what mesh inflation value to use
    %   mesh_alpha: transparency of cortex mesh, 0-1
    %   ROI_radius: radius of spheres to display ROI centroids as
    %   surface_parcels: Boolean value, whether to display surface parcels
    %       (if supported by network atlas) instead of ROI centroids

    import nla.gfx.drawROIsOnCortex nla.gfx.ViewPos nla.gfx.BrainColorMode

    %% Display figures 
    fig = nla.gfx.createFigure(1550, 750);
    fig.Name = net_atlas.name;
    
    ax = subplot('Position',[.45,0.455,.53,.45]);
    drawROIsOnCortex(ax, net_atlas, ctx, 1, ROI_radius, ViewPos.LAT, surface_parcels, BrainColorMode.DEFAULT_NETS);
    
    ax = subplot('Position',[.45,0.005,.53,.45]);
    drawROIsOnCortex(ax, net_atlas, ctx, 1, ROI_radius, ViewPos.MED, surface_parcels, BrainColorMode.DEFAULT_NETS);
    
    ax = subplot('Position',[.075,0.025,.35,.9]);
    drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, ViewPos.DORSAL, surface_parcels, BrainColorMode.DEFAULT_NETS);
    
    light('Position',[0,100,100],'Style','local');

    %% Display legend
    hold(ax, 'on');
    for i = 1:net_atlas.numNets()
        legend_entry = bar(ax, NaN);
        legend_entry.FaceColor = net_atlas.nets(i).color;
        legend_entry.DisplayName = net_atlas.nets(i).name;
    end
    hold(ax, 'off');
    legend(ax);
    nla.gfx.hideAxes(ax);
end