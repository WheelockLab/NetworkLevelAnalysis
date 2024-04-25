function tests = genTests(subpackage)
    %GENTESTS Generate cell array containing all tests in given subpackage
    %   subpackage: dot-seperated subpackage name within NLA namespace, eg.
    %       'net.test' for net-level tests
    root_path = nla.findRootPath();
    rel_path = strrep(subpackage, '.', '/+');
    path_to = [root_path '+nla/+' rel_path];
    net_test_struct = dir(path_to);
    net_test_folder_fnames = {net_test_struct.name};
    net_test_fnames = net_test_folder_fnames(~[net_test_struct.isdir]);

    tests = {};
    for i = 1:numel(network_test_filenames)
        filename_split = split(network_test_filenames{i}, '.');
        if numel(filename_split) == 2 && strcmp(filename_split{2}, 'm')
            test_name = [subpackage '.' filename_split{1}];
            tests{end + 1} = nla.(test_name);
        end
    end
end

