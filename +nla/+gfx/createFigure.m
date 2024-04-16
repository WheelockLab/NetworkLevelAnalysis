function fig = createFigure(w, h)
    %CREATEFIGURE Create and return a figure, with appropriate title,
    %toolbar, etc. settings.
    %   w: width in pixels
    %   h: height in pixels
    import nla.* % required due to matlab package system quirks
    fig = figure('Color', 'w', 'Resize', 'off', 'Name', 'NLA Figure', 'NumberTitle','off');
    %fig.Icon = [findRootPath() 'thumb.png'];
    if exist('w', 'var') && exist('h', 'var') 
        fig.Position(3:4) = [w, h];
    end
    set(fig, 'MenuBar', 'none');
    set(fig, 'ToolBar', 'none');
    
    
    m = uimenu(fig, 'Text', 'File');

    menu_save = uimenu(m,'Text','&Save');
    menu_save.Accelerator = 'S';
    menu_save.MenuSelectedFcn = @saveButtonPressed;

    menu_exit = uimenu(m,'Text','E&xit');
    menu_exit.Accelerator = 'X';
    menu_exit.MenuSelectedFcn = @exitButtonPressed;
    
    function saveButtonPressed(src, ~)
        fig_handle = src.Parent.Parent;
        file_name_default = sprintf('nla_figure_%s.png', datetime(datetime, 'Format', 'yyyy-MM-dd-HH-mm-ss-SS'));
        [file, path] = uiputfile({'*.png', 'Image (*.png)'; '*.svg', 'Scalable Vector Graphic (*.svg)'}, 'Save Figure', file_name_default);
        if file ~= 0
            saveas(fig_handle, fullfile(path, file));
        end
    end

    function exitButtonPressed(src, ~)
        fig_handle = src.Parent.Parent;
        close(fig_handle);
    end
end