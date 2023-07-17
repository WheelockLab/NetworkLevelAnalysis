function drawLine(ax, x, y)
    %DRAWLINE Draw black line segment between two points
    %   ax: axes to draw on
    %   x: x-y position of beginning point
    %   y: x-y position of ending point
    hold(ax, 'on');
    plot(ax, x, y, 'Color', 'k');
    %plot(x, y, 'Color', 'k');
end

