function points = genArcSegment(origin, angles, radius, n)
    %GENARCSEGMENT Generate n points on an arc segment of a given radius
    % from angle A to angle B around the given origin point
    %   origin: x and y coordinates point the arc is centered around (the
    %       center of the circle the arc is a segment of)
    %   angles: angles of the start and end of the arc, in radians
    %   radius: radius of the circle the arc is a segment of
    %   n: number of points to generate (more = smoother)
    
    circ_rad = @(radius,rad_ang, origin)  [radius * cos(rad_ang) + origin(1);  radius * sin(rad_ang) + origin(2)]'; % circle function for angles in radians
    if angles(1) > angles(2) && angles(1) - pi > angles(2)
        % loop around zero
        r_angl = linspace(angles(1), (2 * pi) + angles(2), n);
        looped_around = r_angl > 2 * pi;
        r_angl(looped_around) = r_angl(looped_around) - (2 * pi);
    elseif angles(2) > angles(1) && angles(2) - pi > angles(1)
        % loop around zero
        r_angl = linspace(angles(2), (2 * pi) + angles(1), n);
        looped_around = r_angl > 2 * pi;
        r_angl(looped_around) = r_angl(looped_around) - (2 * pi);
    else
        r_angl = linspace(angles(1), angles(2), n);
    end
    points = circ_rad(radius, r_angl, origin);
end

