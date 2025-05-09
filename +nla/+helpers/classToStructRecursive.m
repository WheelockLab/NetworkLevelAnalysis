function s = classToStructRecursive(c)
    %CLASSTOSTRUCTRECURSIVE Convert classes to structs recursively
    
    if isa(c, 'cell')
        s = cell(size(c));
        for i = 1:numel(c)
            s{i} = nla.helpers.classToStructRecursive(c{i});
        end
        return
    end
    
    if ~isobject(c) || isa(c, 'string')
        s = c;
        return
    end
    
    if numel(c) > 1
        s = cell(size(c));
        for i = 1:numel(c)
            s{i} = nla.helpers.classToStructRecursive(c(i));
        end
        return
    end
    
    if numel(c) == 1
        class_name = class(c);
        if startsWith(class_name, 'nla.')
            s = struct();
            p = properties(c);
            for i = 1:length(p)
                s.(p{i}) = nla.helpers.classToStructRecursive(c.(p{i}));
            end
        else
            s = struct(c);
        end
    end
end

