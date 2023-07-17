function obj = drawCortexHemi(ax, anat_hemi, mesh, color, mesh_alpha)
    % DRAWCORTEXHEMI Draw one hemisphere of the cortex
    %   ax: axes to display in
    %   anat_hemi: anatomy mesh of one hemisphere of the brain
    %   mesh: vertices of anatomy
    %   color: 3x1 vector, cortex mesh color
    %   mesh_alpha: transparency of cortex mesh
    import nla.* % required due to matlab package system quirks
    obj = patch(ax, 'Faces',anat_hemi.elements(:,1:3),'Vertices', mesh,...
        'EdgeColor','none','FaceColor','interp','FaceVertexCData', color,...
        'FaceLighting','gouraud','FaceAlpha',mesh_alpha,...
        'AmbientStrength',0.25,'DiffuseStrength',0.75,'SpecularStrength',0.1);
    obj.Annotation.LegendInformation.IconDisplayStyle = 'off';
end

