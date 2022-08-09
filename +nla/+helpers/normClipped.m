function normalized = normClipped(x, llimit, ulimit)
%NORMCLIPPED clip something between two limits and normalize to 0-1
    import nla.* % required due to matlab package system quirks
    clipped = min(max(x, llimit), ulimit);
    normalized = (clipped - llimit) / (ulimit - llimit);
end

