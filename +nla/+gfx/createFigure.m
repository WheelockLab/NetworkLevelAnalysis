function fig = createFigure(w, h)
    %CREATEFIGURE Create and return a figure
    import nla.* % required due to matlab package system quirks
    fig = figure('Color', 'w', 'Resize', 'off', 'Name', 'NLA Figure', 'NumberTitle','off');
    %fig.Icon = [findRootPath() 'thumb.png'];
    if exist('w', 'var') && exist('h', 'var') 
        fig.Position(3:4) = [w, h];
    end
    set(fig, 'MenuBar', 'none');
    set(fig, 'ToolBar', 'none');
end

