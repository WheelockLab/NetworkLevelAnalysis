function x = findOriginXFromTwoTangents(a, b, rad_a, rad_b)
    slope_a = tan(pi/2 + rad_a);
    slope_b = tan(pi/2 + rad_b);
    x = (b(2) - a(2) + (slope_a * a(1)) - (slope_b * b(1))) / (slope_a - slope_b);
end

