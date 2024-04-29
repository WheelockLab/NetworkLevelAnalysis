function col = valToColor(x, llimit, ulimit, color_map)
    %VALTOCOLOR map values to color map
    
    x_indexed = int32(ceil(nla.helpers.normClipped(x, llimit, ulimit) * (size(color_map, 1) - 1)));
    col = ind2rgb(x_indexed, color_map);
end

