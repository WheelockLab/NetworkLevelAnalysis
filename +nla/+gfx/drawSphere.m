function obj = drawSphere(ax, pos, color, radius)
    import nla.* % required due to matlab package system quirks
    [x, y, z] = sphere(10);
    obj = patch(surf2patch(radius * x + pos(1), radius * y + pos(2), radius * z + pos(3)), 'EdgeColor', color, 'FaceColor', color, 'EdgeAlpha', 0, 'FaceLighting', 'none', 'AmbientStrength', 0.02);
    obj.Annotation.LegendInformation.IconDisplayStyle = 'off';
end

