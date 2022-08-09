function tests = genTests(path_given, prefix)
    %GENTESTS Generate array of tests containing all tests in given directory
    import nla.* % required due to matlab package system quirks
    net_test_struct = dir(path_given);
    net_test_folder_fnames = {net_test_struct.name};
    net_test_fnames = net_test_folder_fnames(~[net_test_struct.isdir]);

    tests = {};
    for i = 1:numel(net_test_fnames)
        fname_split = split(net_test_fnames{i}, '.');
        if numel(fname_split) == 2 && strcmp(fname_split{2}, 'm')
            test_name = [prefix fname_split{1}];
            tests{end + 1} = feval(test_name);
        end
    end
end

