function matching = findMatching(str)
    %FINDMATCHINGFILES Find files matching the given pattern, returns a
    % string array of matching files
    dir_list = string(ls(str));
    if strlength(dir_list) > 0
        matching = split(dir_list);
    else
        matching = {};
    end
end

