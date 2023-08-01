function drawLine(ax, x, y, col)
    %DRAWLINE Draw line segment between two points
    %   ax: axes to draw on
    %   x: x-y position of beginning point
    %   y: x-y position of ending point
    %   col: optional color
    if ~exist('col', 'var'), col = 'k'; end
    hold(ax, 'on');
    plot(ax, x, y, 'Color', col);
end

