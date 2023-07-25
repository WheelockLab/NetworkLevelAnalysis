function z = fisherR2Z(r)
    %FISHERR2Z Transforms r-value data into z-value data via the
    % transform: z = 1/2 ln([1+r]/[1-r]) = arctanh(r)
    % z = arctanh(r);
    z = 0.5 .* (log(1 + r) - log(1 - r));
    z(~isfinite(z)) = 0;