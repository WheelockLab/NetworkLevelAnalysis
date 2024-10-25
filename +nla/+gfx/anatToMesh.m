function [mesh_l, mesh_r] = anatToMesh(anat, ctx, view_pos)
    import nla.gfx.ViewPos nla.gfx.MeshType

    %ANATTOMESH generate cortex hemisphere mesh from anatomy
    %   anat: anatomy struct, contained in cortex mesh files
    %   ctx: MeshType value, what inflation level of mesh to use
    %   view_pos: ViewPos value, which standard view to use
    %   mesh_l: mesh of left hemisphere of brain
    %   mesh_r: mesh of right hemisphere of brain
    %% Choose inflation
    switch ctx
        case MeshType.STD
            mesh_l = anat.hemi_l.nodes;
            mesh_r = anat.hemi_r.nodes;
        case MeshType.INF
            mesh_l = anat.hemi_l.Inodes;
            mesh_r = anat.hemi_r.Inodes;
        case MeshType.VINF
            mesh_l = anat.hemi_l.VInodes;
            mesh_r = anat.hemi_r.VInodes;
    end
    
    %% Small adjustment to separate hemispheres
    mesh_l(:,1) = mesh_l(:,1) - max(mesh_l(:,1));
    mesh_r(:,1) = mesh_r(:,1) - min(mesh_r(:,1));
    
    %% Rotate if necessary
    if view_pos == ViewPos.LAT || view_pos == ViewPos.MED
        dy = -5;
        % rotate right hemi around and move to position for visualization
        cmL = mean(mesh_l, 1);
        cmR = mean(mesh_r, 1);
        rm = nla.helpers.rotationMatrix(nla.Direction.Z, pi);

        % Rotate
        switch view_pos
            case ViewPos.LAT
                mesh_r = (mesh_r - (repmat(cmR, size(mesh_r, 1), 1))) * rm + (repmat(cmR, size(mesh_r, 1), 1));             
            case ViewPos.MED
                mesh_l = (mesh_l - (repmat(cmL, size(mesh_l, 1), 1))) * rm + (repmat(cmL, size(mesh_l, 1), 1));              
        end
        mesh_r(:, 1) = mesh_r(:, 1) + (cmL(:, 1) - cmR(:, 1));    % Shift over to same YZ plane
        mesh_r(:, 2) = mesh_r(:, 2) - max(mesh_r(:, 2)) + min(mesh_l(:, 2)) + dy;
    end
end

