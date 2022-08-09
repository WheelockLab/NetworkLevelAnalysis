function hideAxes(ax)
    import nla.* % required due to matlab package system quirks
    % the sole purpose of this nonsense is to hide the axes border
    % make the axes go away!!!! please!!!!
    ax.Box = 'off';
    ax.XTick = [];
    ax.YTick = [];
    ax.XColor = 'w';
    ax.YColor = 'w';
    ax.DataAspectRatio = [1,1,1];
    ax.TickDir = 'out';
    ax.Visible = 'off';
end

