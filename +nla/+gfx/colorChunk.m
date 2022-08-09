function chunk = colorChunk(color, h, w)
    import nla.* % required due to matlab package system quirks
    %COLORCHUNK create a matrix of size h * w * 3, filled with color
    chunk = repmat(reshape(color,1,1,[]), h, w);
end

