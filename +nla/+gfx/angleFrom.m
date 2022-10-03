function rad = angleFrom(a, b)
    %ANGLEFROM Angle from point a to point b, in radians
    x = b(1) - a(1);
    y = b(2) - a(2);
    rad = abs(atan(y / x));
    
    if x < 0 && y >= 0
        % Q2
        rad = pi - rad;
    elseif x < 0 && y < 0
        % Q3
        rad = rad + pi;
    elseif x >= 0 && y < 0
        % Q4
        rad = (2 * pi) - rad;
    end
end

