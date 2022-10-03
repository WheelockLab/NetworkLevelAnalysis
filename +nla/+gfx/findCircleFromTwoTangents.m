function [origin, rad_origin, radius] = findCircleFromTwoTangents(a, b, rad_a, rad_b)
    %FINDCIRCLEWITHTWOTANGENTS Find the origin and radius of a circle,
    % given two tangent points and slopes
    % Points and slopes MUST be ordered clockwise from the perspective of
    % the circle you are trying to locate
    import nla.* % required due to matlab package system quirks
    
    origin(1) = gfx.findOriginXFromTwoTangents(a, b, rad_a, rad_b);
    
    % transpose axes and do the same thing
    a_2 = [a(2), a(1)];
    b_2 = [b(2), b(1)];
    rad_a_2 = (pi/2) - rad_a;
    rad_b_2 = (pi/2) - rad_b;
    origin(2) = gfx.findOriginXFromTwoTangents(a_2, b_2, rad_a_2, rad_b_2);
    
    rad_origin = [gfx.angleFrom(origin, a), gfx.angleFrom(origin, b)];
    radius = gfx.pointDist(a, origin);
end

