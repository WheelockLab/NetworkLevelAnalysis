function drawChord(ax, ax_width, net_atlas, sig_mat, color_map, sig_type, chord_type, coeff_min, coeff_max, representative)
    %DRAWCHORD display chord plot
    %   ax: axes to plot on, should be square
    %   ax_width: width (assumed to equal height) of axes
    %   net_atlas: respective NetworkAtlas object
    %   sig_mat: TriMatrix of significant values, either Nroipairs or
    %       Nnetpairs
    %   color_map: colormap
    %   sig_type: SigType value, representing whether values increase or
    %       decrease with greater significance
    %   chord_type: PlotType value, whether to show chord or chord edge
    %       plot
    %   coeff_min: Lower bound of values
    %   coeff_max: Upper bound of values
    %   representative: true to Z-order values randomly, false to display
    %       more significant values over less significant ones
    import nla.* % required due to matlab package system quirks
    
    if ~exist('sig_type', 'var'), sig_type = gfx.SigType.INCREASING; end
    if ~exist('chord_type', 'var'), chord_type = nla.PlotType.CHORD; end
    if ~exist('coeff_min', 'var'), coeff_min = 0; end
    if ~exist('coeff_max', 'var'), coeff_max = 1; end
    if ~exist('representative', 'var'), representative = false; end
    axis(ax, [-ax_width / 2, ax_width / 2, -ax_width / 2, ax_width / 2]);
    set(ax,'xtick',[],'ytick',[])
    hold(ax, 'on');

    text_width = 50;
    circle_radius = ((ax_width - (text_width * 2)) / 2);
    text_radius = circle_radius + (text_width / 4);
    
    circle_thickness = 3;
    if chord_type == nla.PlotType.CHORD
        space_between_nets_and_labels = 3;
    else
        space_between_nets_and_labels = 6;
    end
    space_between_nets = 5;
    space_between_nets_rad = atan(space_between_nets / circle_radius);
    
    circle_radius_inner = circle_radius - circle_thickness;
    chord_radius = circle_radius_inner - space_between_nets_and_labels;
    
    if chord_type == nla.PlotType.CHORD
        net_size_rads = 2 * pi / net_atlas.numNets();
        net_pair_size_rads = (net_size_rads - space_between_nets_rad) / (net_atlas.numNets() + 1);

        nets_connected = false(net_atlas.numNets(), net_atlas.numNets() + 1);

        n_arr = TriMatrix(net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
        n2_arr = TriMatrix(net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
        n_idx_arr = TriMatrix(net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
        n2_idx_arr = TriMatrix(net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
    else
        ROI_size_rads = 2 * pi / net_atlas.numROIs();
        for n = 1:net_atlas.numNets()
            net_size(n) = net_atlas.nets(n).numROIs();
        end
        ROI_size_rads = ((2 * pi) - (space_between_nets_rad * net_atlas.numNets())) ./ net_atlas.numROIs();
        net_size_rads_arr = net_size .* ROI_size_rads + space_between_nets_rad;
        net_size_cum = cumsum(net_size_rads_arr(1:n));
    end
    
    for n = 1:net_atlas.numNets()
        if chord_type == nla.PlotType.CHORD
            n_start_rad = (n - 1) * net_size_rads + (space_between_nets_rad / 2);
            n_end_rad = n * net_size_rads - (space_between_nets_rad / 2);
        else
            n_outer_end_rad = net_size_cum(n);
            n_start_rad = n_outer_end_rad - net_size_rads_arr(n) + (space_between_nets_rad / 2);
            n_end_rad = n_outer_end_rad - (space_between_nets_rad / 2);
            n_start_rad_arr(n) = n_start_rad;
        end
        n_center_rad = (n_end_rad + n_start_rad) / 2;
        outer = gfx.genArcSegment([0, 0], [n_start_rad, n_end_rad], circle_radius, 50);
        inner = gfx.genArcSegment([0, 0], [n_start_rad, n_end_rad], circle_radius_inner, 50);
        poly_verts = [outer; flip(inner, 1)];
        poly = polyshape(poly_verts(:, 1), poly_verts(:, 2));
        pg = plot(ax, poly);
        n_color = net_atlas.nets(n).color;
        pg.FaceColor = n_color;
        pg.FaceAlpha = 1;
        pg.EdgeColor = n_color;
        pg.EdgeAlpha = 1;

        text_pos = gfx.genArcSegment([0, 0], [n_start_rad, n_end_rad], text_radius, 3);
        text_pos = text_pos(2, :);
        text_pos(1) = text_pos(1);
        text_angle = n_center_rad + (pi / 2);
        
        name_disp = net_atlas.nets(n).name;
        
        % display network label rotated 90 degrees if the associated
        % network is small and name is large
        if chord_type == nla.PlotType.CHORD_EDGE && net_size_rads_arr(n) < 0.25 && strlength(name_disp) > 5
            if strlength(name_disp) > 8
                name_disp = sprintf("%.7s...", name_disp);
            end
            text_angle = text_angle - (pi / 2);
            if text_angle > pi/2 && text_angle < 3 * pi/2 
                text_angle = text_angle - pi;
                text(text_pos(1), text_pos(2), name_disp, 'HorizontalAlignment', 'right', 'Rotation', rad2deg(text_angle));
            else
                text(text_pos(1), text_pos(2), name_disp, 'HorizontalAlignment', 'left', 'Rotation', rad2deg(text_angle));
            end
        else
            if text_pos(2) > 0
                text_angle = text_angle - pi;
            end
            text(text_pos(1), text_pos(2), name_disp, 'HorizontalAlignment', 'center', 'Rotation', rad2deg(text_angle));
        end

        if chord_type == nla.PlotType.CHORD
            for n2 = n:net_atlas.numNets()
                %% find which nets to connect to
                n_idx = find(nets_connected(n, :) == 0, 1, 'last');
                nets_connected(n, n_idx) = true;

                n2_idx = find(nets_connected(n2, :) == 0, 1, 'last');
                nets_connected(n2, n2_idx) = true;

                n_arr.set(n2, n, n);
                n2_arr.set(n2, n, n2);
                n_idx_arr.set(n2, n, n_idx);
                n2_idx_arr.set(n2, n, n2_idx);
            end
        end
    end
    
    %% draw polygons
    if representative
        idx = randperm(numel(sig_mat.v));
    else
        if sig_type == gfx.SigType.INCREASING
            [~, idx] = sort(sig_mat.v);
        elseif sig_type == gfx.SigType.DECREASING
            [~, idx] = sort(sig_mat.v, 'descend');
        else
            [~, idx] = sort(abs(sig_mat.v));
        end
    end
    
    if chord_type == nla.PlotType.CHORD_EDGE
        row_mat = TriMatrix(repelem(1:net_atlas.numROIs(),net_atlas.numROIs(),1)');
        col_mat = TriMatrix(repelem(1:net_atlas.numROIs(),net_atlas.numROIs(),1));
    end
    
    % ROI locations for edge-level plot
    if chord_type == nla.PlotType.CHORD_EDGE
        for n = 1:net_atlas.numNets()
            for r = 1:net_atlas.nets(n).numROIs()
                ROI_center_rad = n_start_rad_arr(n) + (((r - 1) * ROI_size_rads)) + (ROI_size_rads / 2);
                ROI_center = gfx.genArcSegment([0, 0], [ROI_center_rad, ROI_center_rad], (circle_radius_inner + chord_radius) / 2, 1);
                ROI_centers_rad(net_atlas.nets(n).indexes(r)) = ROI_center_rad;
                ROI_centers(net_atlas.nets(n).indexes(r), :) = ROI_center;
            end
        end
    end
    
    for idx_iter = 1:numel(sig_mat.v)
        i = idx(idx_iter);
        if ~isnan(sig_mat.v(i)) && ((sig_type == gfx.SigType.INCREASING && sig_mat.v(i) > coeff_min) || (sig_type == gfx.SigType.DECREASING && sig_mat.v(i) < coeff_max) || (sig_type == gfx.SigType.ABS_INCREASING && abs(sig_mat.v(i)) > 0))
            %% color
            sig = sig_mat.v(i);
            np_color = gfx.valToColor(sig, coeff_min, coeff_max, color_map);
            np_color = np_color(:); % flatten color matrix to vector
            
            if representative
                np_alpha = 0.5;
            else
                np_alpha = 1;
            end

            if chord_type == nla.PlotType.CHORD
                n = n_arr.v(i);
                n2 = n2_arr.v(i);
                n_idx = n_idx_arr.v(i);
                n2_idx = n2_idx_arr.v(i);

                %% start and end positions of the chord, in radians
                n_start_rad = (n - 1) * net_size_rads + (space_between_nets_rad / 2);
                np1_start_rad = n_start_rad + ((n_idx - 1) * net_pair_size_rads);
                np1_end_rad = np1_start_rad + net_pair_size_rads;

                n2_start_rad = (n2 - 1) * net_size_rads + (space_between_nets_rad / 2);
                np2_start_rad = n2_start_rad + ((n2_idx - 1) * net_pair_size_rads);
                np2_end_rad = np2_start_rad + net_pair_size_rads;
                
                %% start and end points of the chord, in cartesian coordinates
                % for the first net in the pair
                np1_points = gfx.genArcSegment([0, 0], [np1_start_rad, np1_end_rad], chord_radius, 2);
                np1_start = np1_points(1,:);
                np1_end = np1_points(2,:);
                % for the second net in the pair
                np2_points = gfx.genArcSegment([0, 0], [np2_start_rad, np2_end_rad], chord_radius, 2);
                np2_start = np2_points(1,:);
                np2_end = np2_points(2,:);

                %% generate connecting circles between inner/outer points
                [inner_origin, inner_origin_rad, inner_radius] = nla.gfx.findCircleFromTwoTangents(np2_start, np1_end, np2_start_rad + pi, np1_end_rad);
                inner = nla.gfx.genArcSegmentHandlePoorlyDefined(inner_origin, inner_origin_rad, inner_radius, np1_end, np2_start, 50);

                [outer_origin, outer_origin_rad, outer_radius] = gfx.findCircleFromTwoTangents(np2_end, np1_start, np2_end_rad + pi, np1_start_rad);
                outer = nla.gfx.genArcSegmentHandlePoorlyDefined(outer_origin, outer_origin_rad, outer_radius, np1_start, np2_end, 50);
                
                %% construct mesh
                poly_verts = [outer; flip(inner, 1)];
                poly = polyshape(poly_verts(:, 1), poly_verts(:, 2));

                pg = plot(ax, poly);
                
                pg.FaceColor = np_color;
                pg.FaceAlpha = np_alpha;
                pg.EdgeColor = np_color;
                pg.EdgeAlpha = np_alpha;
            else
                r1 = col_mat.v(i);
                r2 = row_mat.v(i);
                r1_center_rad = ROI_centers_rad(r1);
                r2_center_rad = ROI_centers_rad(r2);
                
                r1_center = gfx.genArcSegment([0, 0], [r1_center_rad, r1_center_rad], chord_radius + 1, 1);
                r2_center = gfx.genArcSegment([0, 0], [r2_center_rad, r2_center_rad], chord_radius + 1, 1);
                [arc_origin, arc_origin_rad, arc_radius] = gfx.findCircleFromTwoTangents(r2_center, r1_center, r2_center_rad + pi, r1_center_rad);
                
                % Handle poorly-defined circles
                arc = gfx.genArcSegmentHandlePoorlyDefined(arc_origin, arc_origin_rad, arc_radius, r1_center, r2_center, 50);
                
                pg = plot(ax, arc(:,1), arc(:,2), 'LineWidth', 2);
                pg.Color = [np_color; np_alpha];
            end
        end
    end

    viscircles(ax, [0, 0], circle_radius_inner - (space_between_nets_and_labels / 2), 'Color', 'w', 'LineWidth', space_between_nets_and_labels - 1);
    
    % tick marks for edge-level chord plot
    if chord_type == nla.PlotType.CHORD_EDGE
        for r = 1:net_atlas.numROIs()
            plot(ax, ROI_centers(r, 1), ROI_centers(r, 2), '.k', 'MarkerSize', 3);
        end
    end
end

