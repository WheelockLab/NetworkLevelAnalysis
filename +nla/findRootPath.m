function root_path = findRootPath()
    %FINDROOTPATH Find the root path of the NLA toolbox
    path_split = split(string(which('nla.VERSION')), "/");
    path_joined = join(path_split(1:end-2), "/");
    root_path = char(path_joined + "/");
end

