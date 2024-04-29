function obj = drawSphere(ax, pos, color, radius)
    %DRAWSPHERE Draw sphere
    %   ax: axes to draw on (currently unused)
    %   pos: x-y-z position, center of sphere
    %   color: r-g-b or r-g-b-a color
    %   radius: radius of sphere
    
    [x, y, z] = sphere(10);
    obj = patch(surf2patch(radius * x + pos(1), radius * y + pos(2), radius * z + pos(3)), 'EdgeColor', color,...
        'FaceColor', color, 'EdgeAlpha', 0, 'FaceLighting', 'gouraud', 'AmbientStrength', 0.02);
    
    obj.Annotation.LegendInformation.IconDisplayStyle = 'off';
end

