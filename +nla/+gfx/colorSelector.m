function colorSelector(src, plot_figure, plot_parameters, chord_type, callback_function, color_choices)
    original_figure = src.Parent.Parent;
    modal = figure('WindowStyle', 'normal', 'Units', 'pixels', 'Position',...
        [original_figure.Position(1), original_figure.Position(2), original_figure.Position(3) / 2, original_figure.Position(4) / 3]);

    % Color Map selector
    % Adapted from colormap-dropdown: https://www.mathworks.com/matlabcentral/fileexchange/43659-colormap-dropdown-menu 

    color_map_select = uicontrol('Style', 'popupmenu',...
        'Position', [90, 130, 275, 30], "Units", "pixels",...
        'FontName', 'Courier');
    uicontrol("Style", "text", "string", "Colormaps", "Units", "pixels",...
        "Position", [color_map_select.Position(1) - 80, color_map_select.Position(2) - 2, 80, color_map_select.Position(4)]);
    initial_colors = 16;
    colormap_html = {};
    for colors = 1:numel(color_choices)
        colormap_function = str2func(strcat(strcat("@(x) ",lower(color_choices{colors})), "(x)"));
        CData = colormap_function(initial_colors);
        new_html_start = '<HTML> ';
        new_html = '';
        for color_iterator = initial_colors:-1:1
            hex_code = nla.gfx.rgb2hex([CData(color_iterator, 1), CData(color_iterator, 2),...
                CData(color_iterator, 3)]);
            new_html = [new_html '<FONT bgcolor="' hex_code ' "color="' hex_code '">__</FONT>'];
        end
        new_html_end = [new_html ' </HTML>'];
        new_html = [new_html_start new_html_end];
        colormap_html = [colormap_html; new_html];
    end

    if ~isfield(parameters, "color_map_name")
        parameters.color_map_name = 1;
    end
    set(color_map_select, "Value", parameters.color_map_name, "String", colormap_html);

    apply_button_position = [10, 10, 100, 30];
    apply_button = uicontrol('String', 'Apply',...
        "Callback", {callback_function, false, false, color_map_select, plot_figure, parameters, chord_type},...
        "Units", "pixels",...
        'Position', apply_button_position);
    
    close_button_position = [apply_button.Position(1) + apply_button.Position(3) + 10,...
        apply_button.Position(2), apply_button.Position(3), apply_button.Position(4)];
    uicontrol('String', 'Close', 'Callback', @(~, ~)close(modal), "Units", "pixels", 'Position',...
        close_button_position);
end