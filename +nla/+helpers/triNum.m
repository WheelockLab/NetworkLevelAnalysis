function returned = triNum(n)
    %TRINUM Calculate the nth triangular number
    import nla.* % required due to matlab package system quirks
    returned = (n .* (n + 1)) ./ 2;
end
