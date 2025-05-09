function x = findOriginXFromTwoTangents(a, b, rad_a, rad_b)
    %FINDORIGINXFROMTWOTANGENTS Find circle origin X position from two
    % tangent lines on the circle
    %   a: x-y coordinate, tangent point a
    %   b: x-y coordinate, tangent point b
    %   rad_a: angle from circle origin to tangent point a
    %   rad_b: angle from circle origin to tangent point b
    slope_a = tan(pi/2 + rad_a);
    slope_b = tan(pi/2 + rad_b);
    x = (b(2) - a(2) + (slope_a * a(1)) - (slope_b * b(1))) / (slope_a - slope_b);
end

