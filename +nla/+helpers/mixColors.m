function c3 = mixColors(c1, c2, fac)
%MIXCOLORS Mix two colors at the given factor (between 0 and 1)
    c3 = (c1 .* fac) + (c2 .* (1 - fac));
end

