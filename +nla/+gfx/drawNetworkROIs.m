function drawNetworkROIs(net_atlas, anat, ctx, mesh_alpha, ROI_radius, surface_parcels)
    import nla.* % required due to matlab package system quirks
    %% Display figures 
    fig = gfx.createFigure(1550, 750);
    fig.Name = net_atlas.name;
    
    ax = subplot('Position',[.45,0.455,.53,.45]);
    gfx.drawROIsOnCortex(ax, net_atlas, anat, ctx, 1, ROI_radius, gfx.ViewPos.LAT, surface_parcels);
    
    ax = subplot('Position',[.45,0.005,.53,.45]);
    gfx.drawROIsOnCortex(ax, net_atlas, anat, ctx, 1, ROI_radius, gfx.ViewPos.MED, surface_parcels);
    
    ax = subplot('Position',[.075,0.025,.35,.9]);
    gfx.drawROIsOnCortex(ax, net_atlas, anat, ctx, mesh_alpha, ROI_radius, gfx.ViewPos.DORSAL, surface_parcels);
    
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
    gfx.hideAxes(ax);
end