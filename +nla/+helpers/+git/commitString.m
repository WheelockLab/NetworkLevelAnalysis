function str = commitString(full)
%COMMITSTRING Output current git commit as a string
    
    if ~exist('full', 'var'), full = false; end
    
    cmd_str = sprintf('cd %s\ngit rev-parse --abbrev-ref HEAD', nla.findRootPath());
    [cmd_status, branch_name] = system(sprintf(cmd_str));
    if cmd_status ~= 0
        str = 'Failed to locate git repository';
        return
    end
    
    flag = '--short';
    if full
        flag = '';
    end
    
    [~, commit_hash] = system(sprintf(cmd_str, flag));
    str = sprintf('%s:%s', strip(branch_name), strip(commit_hash));
end

