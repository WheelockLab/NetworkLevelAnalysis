function root_path = findRootPath()
    %FINDROOTPATH Find the root path of the NLA toolbox
    % path_split = split(string(which('nla.VERSION')), "/");
    % path_joined = join(path_split(1:end-2), "/");
    % root_path = char(path_joined + "/");

    root_path_no_ending_slash = fileparts(which('nla.VERSION'));
    %root path will be location of parent folder containing the '+nla'
    %folder. Get this by trimming last 4 characters off of the directory
    %containing nla.VERSION
    root_path = root_path_no_ending_slash(1:(end-4));
    root_path = strrep(root_path, '\','\\'); %Replace windows style path separator with double slash to avoid confusion with escape characters. Has no effect on linux style slashes
    
end

