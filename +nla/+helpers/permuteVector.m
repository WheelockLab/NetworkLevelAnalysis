function returned = permuteVector(vec)
    import nla.* % required due to matlab package system quirks
    returned = vec(randperm(numel(vec)));
end

