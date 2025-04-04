function drawBrainVis(edge_input_struct, input_struct, net_atlas, ctx, mesh_alpha, ROI_radius, surface_parcels, edge_result, net1, net2, sig_based)
    %DRAWBRAINVIS Display correlations between given networks on brain
    %   edge_input_struct: edge-level input struct
    %   input_struct: net-level input struct
    %   net_atlas: relevant NetworkAtlas object
    %   ctx: MeshType object, brain mesh inflation value
    %   mesh_alpha: transparency of cortex mesh
    %   ROI_radius: radius of spheres to display ROI centroids as
    %   surface_parcels: Boolean value, whether to display surface parcels
    %       (if supported by network atlas) instead of ROI centroids
    %   edge_result: edge-level result object
    %   net1: Network to view correlations between
    %   net2: Network to view correlations between
    %   sig_based: whether the net-level test is based on p-values
    %       thresholded by significance (for example, Chi2, HG)
 
    fc_exists = isfield(edge_input_struct, 'func_conn');

    color_fc = false; % short term fix for NET-167 
    % color_fc = fc_exists;

    show_ROI_centroids = true;
    if isfield(input_struct, 'show_ROI_centroids')
        show_ROI_centroids = input_struct.show_ROI_centroids;
    end
    
    %% Display figures 
    fig = nla.gfx.createFigure(1550, 750);
    figure_title = sprintf('Brain Visualization: Average of edge-level correlations between nets in [%s - %s] Network Pair', net_atlas.nets(net1).name, net_atlas.nets(net2).name);
    
    if sig_based
        figure_title = [figure_title sprintf(' (Edge-level P < %.2g)', edge_input_struct.prob_max)];
    end
    
    fig.Name = figure_title;
    
    llimit = edge_result.coeff_range(1);
    ulimit = edge_result.coeff_range(2);
    
    % This is the colormap if there's no functional connectivity provided
    % color_map = parula(); % parula is a little gentler than turbo

    % color_man_n = color map negative, color_man_p = color map positive
    color_map_n = winter(1000);
    
    % Luckily, 'autumn' has the colors we want for warmth
    color_map_p = flip(autumn(1000));

    color_map = cat(1, color_map_n, color_map_p);
    
    ROI_vals = nan(net_atlas.numROIs(), 1);
    fc_vals = nan(net_atlas.numROIs(), 1);
	net1_ROI_indexes = net_atlas.nets(net1).indexes;
    net2_ROI_indexes = net_atlas.nets(net2).indexes;
    
    function [coeff1, coeff2, fc1, fc2] = get_coeffs(n1, n2, edge_input_struct, edge_result, fc_exists, sig_based)
        coeff1 = edge_result.coeff.get(n1, n2);
        coeff2 = edge_result.coeff.get(n2, n1);
        if fc_exists
            fc1 = mean(edge_input_struct.func_conn.get(n1, n2), 2);
            fc2 = mean(edge_input_struct.func_conn.get(n2, n1), 2);
        else
            fc1 = false;
            fc2 = false;
        end
        
        if sig_based
            prob_sig1 = edge_result.prob_sig.get(n1, n2);
            prob_sig2 = edge_result.prob_sig.get(n2, n1);
            
            coeff1 = coeff1(logical(prob_sig1));
            coeff2 = coeff2(logical(prob_sig2));
            fc1 = fc1(logical(prob_sig1));
            fc2 = fc2(logical(prob_sig2));
        end
    end
    
    for ROI_idx_iter = 1:numel(net1_ROI_indexes)
        ROI_idx = net1_ROI_indexes(ROI_idx_iter);
        [c1, c2, fc1, fc2] = get_coeffs(ROI_idx, net2_ROI_indexes, edge_input_struct, edge_result, fc_exists, sig_based);
        ROI_vals(ROI_idx) = (sum(c1) + sum(c2)) / (numel(c1) + numel(c2));
        fc_vals(ROI_idx) = (sum(fc1) + sum(fc2)) / (numel(fc1) + numel(fc2));
    end
    
    for ROI_idx_iter = 1:numel(net2_ROI_indexes)
        ROI_idx = net2_ROI_indexes(ROI_idx_iter);
        [c1, c2, fc1, fc2] = get_coeffs(ROI_idx, net1_ROI_indexes, edge_input_struct, edge_result, fc_exists, sig_based);
        ROI_val = (sum(c1) + sum(c2)) / (numel(c1) + numel(c2));
        fc_val = (sum(fc1) + sum(fc2)) / (numel(fc1) + numel(fc2));
        if net1 == net2
            ROI_vals(ROI_idx) = (ROI_vals(ROI_idx) + ROI_val) ./ 2;
            fc_vals(ROI_idx) = (fc_vals(ROI_idx) + fc_val) ./ 2;
        else
            ROI_vals(ROI_idx) = ROI_val;
            fc_vals(ROI_idx) = fc_val;
        end
    end

    function cols = valsToColor(ROI_vals, fc_vals, color_map, color_map_p, color_map_n, color_fc, llimit, ulimit)
        import nla.gfx.valToColor

        if color_fc
            cols_p = valToColor(fc_vals, -0.5, 0.5, color_map_p);
            cols_n = valToColor(fc_vals, -0.5, 0.5, color_map_n);
            cols(ROI_vals > 0, :) = cols_p(ROI_vals > 0, :);
            cols(ROI_vals <= 0, :) = cols_n(ROI_vals <= 0, :);
        else
            cols = valToColor(ROI_vals, llimit, ulimit, color_map);
        end
    end
    
    % map colors to limits
    color_mat = valsToColor(ROI_vals, fc_vals, color_map, color_map_p, color_map_n, color_fc, llimit, ulimit);
    color_mat(isnan(ROI_vals), :) = 0.50;
    conn = ~isnan(ROI_vals);
    
    function drawROISpheres(ROI_pos, ax, net_atlas, net1, net2, ROI_radius, conn_map)
        for n = [net1, net2]
            indexes = net_atlas.nets(n).indexes;
            for j_idx = 1:numel(indexes)
                j = indexes(j_idx);
                
                if conn_map(j)
                    % render a sphere at each ROI location
                    nla.gfx.drawSphere(ax, ROI_pos(j, :), net_atlas.nets(n).color, ROI_radius);
                end
            end
        end
    end

    function drawEdges(ROI_pos, ax, net_atlas, net1, net2, color_map, color_map_p, color_map_n, color_fc, fc_exists, llimit, ulimit, edge_input_struct, edge_result, sig_based)
        a_indexes = net_atlas.nets(net1).indexes;
        b_indexes = net_atlas.nets(net2).indexes;
        for a_idx = 1:numel(a_indexes)
            a = a_indexes(a_idx);
            for b_idx = 1:numel(b_indexes)
                b = b_indexes(b_idx);
                if a < b
                    n1 = b;
                    n2 = a;
                else
                    n1 = a;
                    n2 = b;
                end
                
                [val, ~, fc_vals_vec, ~] = get_coeffs(n1, n2, edge_input_struct, edge_result, fc_exists, sig_based);
                fc_val_avg = mean(fc_vals_vec);
                
                if ~isempty(val)
                    col = valsToColor(val, fc_val_avg, color_map, color_map_p, color_map_n, color_fc && fc_exists, llimit, ulimit);
                    col = [reshape(col, [1, 3]), 0.5];
                    p = plot3(ax, [ROI_pos(n1, 1), ROI_pos(n2, 1)], [ROI_pos(n1, 2), ROI_pos(n2, 2)],...
                        [ROI_pos(n1, 3), ROI_pos(n2, 3)], 'Color', col, 'LineWidth', 5);
                    p.Annotation.LegendInformation.IconDisplayStyle = 'off';
                end
            end
        end
    end
    
    function onePlot(varargin)
        if nargin >= 3
            ax = varargin{1};
            pos = varargin{2};
            color_mode = varargin{3};
        end
        if nargin >= 4
            color_mat = varargin{4};
        end
        if nargin > 4
            ulimit = str2double(varargin{5});
            llimit = str2double(varargin{6});
        end    

        if color_mode == nla.gfx.BrainColorMode.NONE
            ROI_final_pos = nla.gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, pos, surface_parcels,...
                nla.gfx.BrainColorMode.NONE);
            drawEdges(ROI_final_pos, ax, net_atlas, net1, net2, color_map, color_map_p, color_map_n, color_fc, fc_exists,...
                llimit, ulimit, edge_input_struct, edge_result, sig_based);
        else
            ROI_final_pos = nla.gfx.drawROIsOnCortex(ax, net_atlas, ctx, 1, ROI_radius, pos, surface_parcels,...
                nla.gfx.BrainColorMode.COLOR_ROIS, color_mat);
        end
        
        if show_ROI_centroids
            drawROISpheres(ROI_final_pos, ax, net_atlas, net1, net2, ROI_radius, conn);
        end
    end

    if surface_parcels && ~islogical(net_atlas.parcels)
        onePlot(subplot('Position',[.45,0.505,.53,.45]), nla.gfx.ViewPos.LAT, nla.gfx.BrainColorMode.COLOR_ROIS, color_mat);
        onePlot(subplot('Position',[.45,0.055,.53,.45]), nla.gfx.ViewPos.MED, nla.gfx.BrainColorMode.COLOR_ROIS, color_mat);
    else
        onePlot(subplot('Position',[.45,0.505,.26,.45]), nla.gfx.ViewPos.BACK, nla.gfx.BrainColorMode.NONE);
        onePlot(subplot('Position',[.73,0.505,.26,.45]), nla.gfx.ViewPos.FRONT, nla.gfx.BrainColorMode.NONE);
        onePlot(subplot('Position',[.45,0.055,.26,.45]), nla.gfx.ViewPos.LEFT, nla.gfx.BrainColorMode.NONE);
        onePlot(subplot('Position',[.73,0.055,.26,.45]), nla.gfx.ViewPos.RIGHT, nla.gfx.BrainColorMode.NONE);
    end
    
    if color_fc
        ax = subplot('Position',[.075,0.175,.35,.75]);
    else
        ax = subplot('Position',[.075,0.025,.35,.85]);
    end
    
    if surface_parcels && ~islogical(net_atlas.parcels)
        onePlot(ax, nla.gfx.ViewPos.DORSAL, nla.gfx.BrainColorMode.COLOR_ROIS, color_mat);
    else
        onePlot(ax, nla.gfx.ViewPos.DORSAL, nla.gfx.BrainColorMode.NONE);
    end
    
    light('Position',[0,100,100],'Style','local');
    
    %% Display legend
    hold(ax, 'on');
    if net1 == net2
        legend_entry = bar(ax, NaN);
        legend_entry.FaceColor = net_atlas.nets(net1).color;
        legend_entry.DisplayName = net_atlas.nets(net1).name;
    else
        for i = [net1, net2]
            legend_entry = bar(ax, NaN);
            legend_entry.FaceColor = net_atlas.nets(i).color;
            legend_entry.DisplayName = net_atlas.nets(i).name;
        end
    end
    hold(ax, 'off'); 
    nla.gfx.hideAxes(ax);
    
    function openModal(source, ~)
        d = figure("WindowStyle", "normal", "Units", "pixels", "Position", [source.Parent.Position(1), source.Parent.Position(2), 250, 150]);
        upper_limit_box = uicontrol("Style", "edit", "Units", "pixels", "Position", [d.Position(3) / 2, d.Position(4) / 2 + 5, 50, 25], "String", ulimit);
        lower_limit_box = uicontrol("Style", "edit", "Units", "pixels", "Position", [d.Position(3) / 2, d.Position(4) / 2 - upper_limit_box.Position(4) - 5, 50, 25], "String", llimit);
        uicontrol("Style", "text", "String", "Upper Limit", "Units", "pixels", "Position", [upper_limit_box.Position(1) - 80, upper_limit_box.Position(2) - 5, 80, upper_limit_box.Position(4)]);
        uicontrol("Style", "text", "String", "Lower Limit", "Units", "pixels", "Position", [lower_limit_box.Position(1) - 80, lower_limit_box.Position(2) - 5, 80, lower_limit_box.Position(4)]);

        apply_button_position = [d.Position(3) / 2 - 85, 10, 80, 25];
        close_button_position = [apply_button_position(1) + 85, apply_button_position(2), apply_button_position(3), apply_button_position(4)];
        uicontrol("String", "Apply", "Units", "pixels", "Position", apply_button_position, "Callback", {@applyScale, upper_limit_box, lower_limit_box});
        uicontrol("String", "Close", "Units", "pixels", "Position", close_button_position, "Callback", @(~, ~)close(d));
    end

    function applyScale(~, ~, upper_limit_box, lower_limit_box)
        upper_limit = get(upper_limit_box, "String");
        lower_limit = get(lower_limit_box, "String");
        figure(fig)
        if surface_parcels && ~islogical(net_atlas.parcels)
            onePlot(subplot('Position',[.45,0.505,.53,.45]), nla.gfx.ViewPos.LAT, nla.gfx.BrainColorMode.COLOR_ROIS, color_mat, upper_limit, lower_limit);
            onePlot(subplot('Position',[.45,0.055,.53,.45]), nla.gfx.ViewPos.MED, nla.gfx.BrainColorMode.COLOR_ROIS, color_mat, upper_limit, lower_limit);
        else
            onePlot(subplot('Position',[.45,0.505,.26,.45]), nla.gfx.ViewPos.BACK, nla.gfx.BrainColorMode.NONE, false, upper_limit, lower_limit);
            onePlot(subplot('Position',[.73,0.505,.26,.45]), nla.gfx.ViewPos.FRONT, nla.gfx.BrainColorMode.NONE, false,  upper_limit, lower_limit);
            onePlot(subplot('Position',[.45,0.055,.26,.45]), nla.gfx.ViewPos.LEFT, nla.gfx.BrainColorMode.NONE, false, upper_limit, lower_limit);
            onePlot(subplot('Position',[.73,0.055,.26,.45]), nla.gfx.ViewPos.RIGHT, nla.gfx.BrainColorMode.NONE, false, upper_limit, lower_limit);
        end
        % ROI_final_pos = nla.gfx.drawROIsOnCortex(ax, net_atlas, ctx, mesh_alpha, ROI_radius, pos, surface_parcels,...
        %         nla.gfx.BrainColorMode.NONE);   
        % drawEdges(ROI_final_pos, ax, net_atlas, net1, net2, color_map, color_map_p, color_map_n, color_fx, fc_exists, lower_limit, upper_limit);
    end

    %% Display colormap
    if color_fc
        % legend(ax, 'Location', 'best');
        % colorbar_ax = subplot('Position',[.02,0,0.4,0.1]);
        % colorbar_image = imread('+nla/+gfx/+images/brain_vis_fc_colormap.png');
        % dims = size(colorbar_image);
        % image(colorbar_ax, colorbar_image);
        colormap(ax, color_map);
        color_bar = colorbar(ax);
        color_bar.Location = 'southoutside';
        % gfx.hideAxes(colorbar_ax);
        % colorbar_ax.Units = 'pixels';
        % colorbar_ax.Position(3:4) = [dims(2), dims(1)];
    else
        num_ticks = 10;
        colormap(ax, color_map);
        cb = colorbar(ax);
        cb.Location = 'southoutside';
        cb.Label.String = 'Coefficient Magnitude';
        cb.ButtonDownFcn = @openModal;
        ticks = [0:num_ticks];
        cb.Ticks = double(ticks) ./ num_ticks;

        % tick labels
        labels = {};
        for i = ticks
            labels{i + 1} = sprintf("%.2g", llimit + (i * ((double(ulimit - llimit) / num_ticks))));
        end
        cb.TickLabels = labels;
        caxis(ax, [0, 1]);
    end
end