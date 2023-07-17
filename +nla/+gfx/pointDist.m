function d = pointDist(p1, p2)
    %POINTDIST Calculate euclidian distance between points
    %   p1: 2-tuple containing x and y coordinates of point
    %   p2: 2-tuple containing x and y coordinates of point
    d_x = p1(1) - p2(1);
    d_y = p1(2) - p2(2);
    d = sqrt((d_x ^ 2) + (d_y ^ 2));
end

