function arc = genArcSegmentHandlePoorlyDefined(arc_origin, arc_origin_rad, arc_radius, r1_center, r2_center, n)
    %GENARCSEGMENTHANDLEPOORLYDEFINED Wrapper around genArcSegment that
    % handles poorly-defined arc segments - radius = 0 or arc of infinite
    % radius (aka. straight line segment)
    import nla.* % required due to matlab package system quirks
    if arc_radius < 1e-10
        arc = arc_origin;
    elseif abs(arc_origin_rad(1) - arc_origin_rad(2)) < 1e-10
        arc = [r1_center; r2_center];
    else
        arc = gfx.genArcSegment(arc_origin, arc_origin_rad, arc_radius, n);
    end
end