function normalized = normClipped(x, llimit, ulimit)
%NORMCLIPPED clip something between two limits and normalize to 0-1
    clipped = min(max(x, llimit), ulimit);
    normalized = (clipped - llimit) / (ulimit - llimit);
end

