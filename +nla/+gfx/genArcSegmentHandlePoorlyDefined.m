function arc = genArcSegmentHandlePoorlyDefined(arc_origin, arc_origin_rad, arc_radius, r1_center, r2_center, n)
    %GENARCSEGMENTHANDLEPOORLYDEFINED Wrapper around genArcSegment that
    % handles poorly-defined arc segments - those with radius = 0 or arc of
    % infinite radius (aka. straight line segment)
    % from angle A to angle B around the given origin point
    %   arc_origin: x and y coordinates point the arc is centered around
    %       (the center of the circle the arc is a segment of)
    %   arc_origin_rad: angles of the start and end of the arc, in radians
    %   arc_radius: radius of the circle the arc is a segment of
    %   r1_center: starting position of arc, x-y coordinate
    %   r2_center: ending position of arc, x-y coordinate
    %   n: number of points to generate (more = smoother)
    
    if arc_radius < 1e-10
        arc = arc_origin;
    elseif abs(arc_origin_rad(1) - arc_origin_rad(2)) < 1e-10
        arc = [r1_center; r2_center];
    else
        arc = nla.gfx.genArcSegment(arc_origin, arc_origin_rad, arc_radius, n);
    end
end