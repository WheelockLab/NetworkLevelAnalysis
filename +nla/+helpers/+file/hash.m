function hash = hash(fpath)
    %HASHFILE Generate hash of file contents
    f_str = fileread(fpath);
    hash = mlreportgen.utils.hash(f_str);
end

