function root_path = findRootPath()
    %FINDROOTPATH Find root path of NLA
    import nla.* % required due to matlab package system quirks
    path_split = split(which('nla.VERSION'), '/');
    path_joined = join(path_split(1:end-2), '/');
    root_path = [path_joined{1} '/'];
end

