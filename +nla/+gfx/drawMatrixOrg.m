function [width, height] = drawMatrixOrg(fig, axes_loc_x, axes_loc_y, name, matrix, llimit, ulimit, networks, fig_size, fig_margins, draw_legend, draw_colorbar, color_map, marked_networks, discrete_colorbar, net_clicked_callback)
    import nla.* % required due to matlab package system quirks
    %DRAWMATRIXORG Draw a matrix or TriMatrix, organized into networks
    %   fig: figure to draw in
    %   x: x-position to draw at, within the figure
    %   y: y-position to draw at, within the figure
    %   name: display name of the plot
    %   matrix: Matrix or TriMatrix
    %   llimit, ulimit: what values to clip input matrix at
    %   networks: Vector of objects which must implement IndexGroup, ie:
    %       have a name, color, and a vector of indices corresponding to
    %       data in the input matrix
    %   fig_size: size to display at, small or large
    %   fig_margins: Margin size
    %   draw_legend: Whether to display a legend
    %   draw_colorbar: Whether to display a colorbar
    %   color_map: color map to use for the matrix
    %   marked_networks: networks to mark with a symbol
    %   discrete_colorbar: whether to display the colorbar as continous or
    %   discrete.
    %   net_clicked_callback: button function to add to each network, for clickable
    %   networks.
    
    fig.Renderer = 'painters';
    
    %% Parameters    
    if ~exist('color_map', 'var'), color_map = turbo(256); end
    if ~exist('marked_networks', 'var'), marked_networks = false; end
    if ~exist('discrete_colorbar', 'var'), discrete_colorbar = false; end
    if ~exist('net_clicked_callback', 'var'), net_clicked_callback = false; end
    
    % Convert to common type of matrix so we can use the same interface for
    % both. If Matlab supported operator overriding this wouldn't have to
    % happen.
    if ~isequal(marked_networks, false) && isa(marked_networks, 'TriMatrix')
        marked_networks = marked_networks.asMatrix();
    end
    mat_type = gfx.MatrixType.MATRIX;
    if isa(matrix, 'TriMatrix')
        if ~isnumeric(matrix.v)
            % If this doesn't work (ie: program errors here), your data is
            % not of a numeric type, and cannot be converted to a numeric
            % type, which means it cannot be displayed.
            matrix.v = single(matrix.v);
        end
        matrix = matrix.asMatrix();
        mat_type = gfx.MatrixType.TRIMATRIX;
    end
    
    % Does the matrix correspond 1-1 to the network?
    network_matrix = false;
    if size(matrix, 1) == numel(networks)
        network_matrix = true;
    end
    
    num_nets = numel(networks);
    
    % size of input matrix
    mat_size = size(matrix, 1);
    % size of matrix as displayed - only number of indexes in included nets
    disp_mat_size = 0;
    if network_matrix
        disp_mat_size = num_nets;
    else
        for i = 1:numel(networks)
            disp_mat_size = disp_mat_size + networks(i).numROIs();
        end
    end
    
    % thickness of network label
    label_size = 13;
    if fig_size == gfx.FigSize.LARGE
        label_size = 20;
    end
    
    %% Scale of elements
    element_size = 1;
    if network_matrix
        element_size = floor(325 / num_nets);
        if fig_size == gfx.FigSize.LARGE
            element_size = floor(500 / num_nets);
        end
    else
        if fig_size == gfx.FigSize.LARGE
            % If a parcellation has many ROIs we might have to plot each
            % individual one smaller.
            if size(matrix, 1) <= 500
                element_size = 2;
            else
                element_size = 1;
            end
        end
    end
    
    colorbar_width = 25;
    colorbar_offset = 15;
    colorbar_text_w = 50;
    legend_offset = 5;
    
    %% Image dimensions
    image_h = (disp_mat_size * element_size) + num_nets + label_size + 2;
    image_w = image_h;
    if ~network_matrix
        image_w = image_w - 1;
    end
    
    %% Image margins
    offset_x = 0;
    offset_y = 0;

    if fig_margins == gfx.FigMargins.WHITESPACE
        offset_x = 50;
        offset_y = 50;
        image_w = image_w + (offset_x * 2);
        image_h = image_h + (offset_y * 2);
    end
    
    plot_w = image_w;
    plot_h = image_h;
    
    if ~isempty(name)
        image_h = image_h + 20;
    end
    
    %% Colorbar margins
    if draw_colorbar
        image_w = image_w + colorbar_width + colorbar_offset + colorbar_text_w;
    end
    
    %% Create axes
    ax = uiaxes(fig, 'Position', [axes_loc_x, axes_loc_y, image_w, image_h]);
    axis(ax, 'image');
    ax.XAxis.TickLabels = {};
    ax.YAxis.TickLabels = {};
    
    %% Create image matrix
    % make the image out of NaNs because we can set NaN's invisible, thus
    % creating transparent areas
    image_data = NaN(image_h, image_w, 3);
    
    %% Display image
    % Display image and stretch to fill axes
    image_display = image(ax, image_data, 'XData', [1 ax.Position(3)], 'YData', [1 ax.Position(4)]);
    % network buttons
    net_dims = zeros(num_nets, num_nets, 4);
    
    function clickedCallback(~, ~)
        if ~isequal(net_clicked_callback, false)
            % get point clicked
            coords = get(ax, 'CurrentPoint'); 
            coords = coords(1,1:2);
            % find network membership
            for y_iter = 1:num_nets
                for x_iter = 1:y_iter
                    net_coords = net_dims(x_iter, y_iter, :);
                    click_padding = 1;
                    if (coords(1) >= net_coords(1) - click_padding) && (coords(1) <= net_coords(2) + click_padding) && (coords(2) >= net_coords(3) - click_padding) && (coords(2) <= net_coords(4) + click_padding)
                        % call callback using clicked network
                        net_clicked_callback(y_iter, x_iter);
                    end
                end
            end
        end
    end

    function addCallback(x)
        if ~isequal(net_clicked_callback, false)
            x.ButtonDownFcn = @clickedCallback;
        end
    end

    addCallback(image_display);
    
    % Set limits of axes
    ax.XLim = [0 image_display.XData(2)];
    ax.YLim = [0 image_display.YData(2) + 1];
    
    y_pos = offset_y + 2;
    if ~isempty(name)
        y_pos = y_pos + 20;
    end
    y_starting_pos = y_pos;
    for y = 1:num_nets
        y_ind = y;
        if ~network_matrix
            y_in_bound = networks(y).indexes <= mat_size;
            y_ind = networks(y).indexes(y_in_bound);
        end
        chunk_h = numel(y_ind) * element_size;
        
        % draw left labels
        top = y_pos;
        bot = y_pos + chunk_h;
        left = offset_x + 2;
        right = offset_x + label_size + 1;
        image_display.CData(top:bot, left:right + 1, :) = gfx.colorChunk(networks(y).color, chunk_h + 1, label_size + 1);
        gfx.drawLine(ax, [left - 1, right], [top - 1, top - 1]);
        gfx.drawLine(ax, [left - 1, right], [bot, bot]);
        gfx.drawLine(ax, [left - 1, left - 1], [top - 1, bot]);
        
        x_pos = label_size + offset_x + 3;
        x_starting_pos = x_pos;
        
        x_max = num_nets;
        % if it's a lower triangle, don't bother iterating the upper parts
        if mat_type == gfx.MatrixType.TRIMATRIX
            x_max = y;
        end
        
        for x = 1:x_max
            x_ind = x;
            if ~network_matrix
                x_in_bound = networks(x).indexes < mat_size;
                x_ind = networks(x).indexes(x_in_bound);
            end
            chunk_w = numel(x_ind) * element_size;
            
            % fill chunk of image
            chunk_raw = matrix(y_ind, x_ind);
            chunk = gfx.valToColor(chunk_raw, llimit, ulimit, color_map);
            
            chunk(isnan(chunk_raw)) = NaN; % duplicate NaNs removed by colormapping process
            
            image_display.CData(y_pos:y_pos + chunk_h - 1, x_pos:x_pos + chunk_w - 1, :) = repelem(chunk, element_size, element_size);
            
            % fill space up to lines
            image_display.CData(y_pos + chunk_h, x_pos:x_pos + chunk_w - 1, :) = repelem(chunk(size(chunk, 1), 1:size(chunk, 2), :), 1, element_size);
            image_display.CData(y_pos:y_pos + chunk_h - 1, x_pos + chunk_w, :) = repelem(chunk(1:size(chunk, 1), size(chunk, 2), :), element_size, 1);
            
            % plot significance marker
            if ~isequal(marked_networks, false) && (marked_networks(y,x) == true)
                cx = x_pos + (chunk_w / 2);
                cy = y_pos + (chunk_h / 2);
                hold(ax, 'on');
                marker_h = plot(ax, cx, cy, 'x', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
                
                if ~isequal(net_clicked_callback, false)
                    marker_h.ButtonDownFcn = @clickedCallback;
                end
            end
            
            % store network bounds for later use
            if ~isequal(net_clicked_callback, false)
                net_dims(x,y,:) = [x_pos, x_pos + chunk_w - 1, y_pos, y_pos + chunk_h - 1];
            end

            % draw lines left of and below each chunk
            addCallback(gfx.drawLine(ax, [x_pos - 1, x_pos - 1], [y_pos, y_pos + chunk_h + 1]));
            addCallback(gfx.drawLine(ax, [x_pos - 2, x_pos + chunk_w - 1], [y_pos + chunk_h, y_pos + chunk_h]));
            
            % draw on-diagonal boundary lines for network matrices
            if x == x_max && mat_type == gfx.MatrixType.TRIMATRIX && network_matrix
                addCallback(gfx.drawLine(ax, [x_pos + chunk_w, x_pos + chunk_w], [y_pos - 1, y_pos + chunk_h + 1]));
                addCallback(gfx.drawLine(ax, [x_pos - 2, x_pos + chunk_w], [y_pos - 1, y_pos - 1]));
            end
            
            % draw bottom labels
            if y == num_nets
                top = y_pos + chunk_h;
                bot = y_pos + chunk_h + label_size;
                left = x_pos;
                right = x_pos + chunk_w;
                
                image_display.CData(top:bot, left:right, :) = gfx.colorChunk(networks(x).color, label_size + 1, chunk_w + 1);
                
                addCallback(gfx.drawLine(ax, [left - 1, left - 1], [top, bot]));
                addCallback(gfx.drawLine(ax, [right, right], [top, bot]));
                addCallback(gfx.drawLine(ax, [left - 1, right], [bot, bot]));
            end
            
            x_pos = x_pos + chunk_w + 1;
        end
        
        y_pos = y_pos + chunk_h + 1;
    end
    
    image_display.AlphaData = ~isnan(image_display.CData(:,:,1)); % make NaNs transparent
    
    %% draw diagonal line on edge-level triangular matrices
    if mat_type == gfx.MatrixType.TRIMATRIX && ~network_matrix
        gfx.drawLine(ax, [x_starting_pos - 1, x_pos - 1], [y_starting_pos - 3 + element_size, y_pos - 2], 'w');
        gfx.drawLine(ax, [x_starting_pos - 2, x_pos - 1], [y_starting_pos - 3 + element_size, y_pos - 1]);
    end
    
    %% Colorbar
    if draw_colorbar
        if discrete_colorbar
            num_ticks = double(ulimit - llimit);
            disp_color_map = color_map(floor((size(color_map,1) - 1) * [0:num_ticks] ./ num_ticks) + 1, :);
            disp_color_map = repelem(disp_color_map, 2, 1);
            disp_color_map = disp_color_map(2:((num_ticks + 1) * 2 - 1), :);
            colormap(ax, disp_color_map);
        else
            num_ticks = min(size(color_map, 1) - 1, 10);
            colormap(ax, color_map);
        end
        
        cb = colorbar(ax);
        
        ticks = [0:num_ticks];
        cb.Ticks = double(ticks) ./ num_ticks;
        
        % tick labels
        labels = {};
        for i = ticks
            labels{i + 1} = sprintf("%.2g", llimit + (i * ((double(ulimit - llimit) / num_ticks))));
        end
        cb.TickLabels = labels;
        
        % colorbar position
        cb.Units = 'pixels';
        cb.Location = 'east';
        cb.Position = [cb.Position(1) - offset_x, cb.Position(2) + offset_y, colorbar_width, image_h - (offset_y * 2) - 20];
        caxis(ax, [0, 1]);
    end
    
    %% Legend
    if draw_legend
        % legend entries
        legend_entries = [];
        for i = 1:num_nets
            legend_entry = bar(ax, NaN);
            legend_entry.FaceColor = networks(i).color;
            legend_entry.DisplayName = networks(i).name;
            legend_entries(end+1) = legend_entry;
        end
        
        % legend
        leg = legend(ax, legend_entries);
        
        % legend position
        leg.Units = 'pixels';
        legend_width = leg.Position(3);
        legend_height = leg.Position(4);
        leg.Position = [axes_loc_x + plot_w - legend_width - offset_x - legend_offset, axes_loc_y + plot_h - legend_height - offset_y, legend_width, legend_height];
    end
    
    %% Name/title
    if ~isempty(name)
        t = title(ax, ' ');
        text(ax, plot_w / 2, offset_y / 2, name, 'FontName', t.FontName, 'FontSize', 14, 'FontWeight', t.FontWeight, 'HorizontalAlignment', 'center');
    end
    
    %% General axes settings
    gfx.hideAxes(ax); % hide axes lines
    ax.DataAspectRatio = [1,1,1];
    ax.Toolbar.Visible = 'off'; % disable zoom/etc
    disableDefaultInteractivity(ax); % disable zoom/etc
    
    %% Fix line rendering bugs
    if ~network_matrix
        set(ax,'units','pixels');
        axpos = get(ax, 'position');
        set(ax,'xlim',[0, axpos(3)]);
        set(ax,'ylim',[0, axpos(4)]);
    end
    
    hold(ax, 'off');
    
    %% Return final width and height
    width = image_w;
    height = image_h;
end

