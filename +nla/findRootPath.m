function root_path = findRootPath()
    %FINDROOTPATH Find the root path of the NLA toolbox
    import nla.* % required due to matlab package system quirks
    path_split = split(string(which('nla.VERSION')), "/");
    path_joined = join(path_split(1:end-2), "/");
    root_path = char(path_joined + "/");
end

