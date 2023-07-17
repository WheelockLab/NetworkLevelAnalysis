function hideAxes(ax)
    %HIDEAXES Hide axes borders and tick marks
    %   ax: axes to modify
    import nla.* % required due to matlab package system quirks
    ax.Box = 'off';
    ax.XTick = [];
    ax.YTick = [];
    ax.XColor = 'w';
    ax.YColor = 'w';
    ax.TickDir = 'out';
    ax.Visible = 'off';
    disableDefaultInteractivity(ax)
end

