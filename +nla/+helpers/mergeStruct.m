function c = mergeStruct(a, b)
%MERGESTRUCT Merge two structures, with the second overwriting the first if
%they set the same key
    c = a;
    fnames = fieldnames(b);
    for n = 1:numel(fnames)
        c.(fnames{n}) = b.(fnames{n});
    end
end

