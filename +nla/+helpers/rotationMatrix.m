function mat = rotationMatrix(dir, theta)
    % Generate a rotation matrix for the direction given
    % an angle (in radians).
    import nla.Dir

    mat = zeros(3);

    switch dir
        case Dir.X
            mat = [1 0 0;...
                    0 cos(theta) -sin(theta);...
                    0 sin(theta) cos(theta)];
        case Dir.Y
            mat = [cos(theta) 0 sin(theta);...
                    0 1 0;...
                    -sin(theta) 0 cos(theta)];
        case Dir.Z
            mat = [cos(theta) -sin(theta) 0;...
                    sin(theta) cos(theta) 0;...
                    0 0 1];
    end
end