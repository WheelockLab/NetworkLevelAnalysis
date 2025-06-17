function tests = genTests(subpackage)
    %GENTESTS Generate cell array containing all tests in given subpackage
    %   subpackage: dot-seperated subpackage name within NLA namespace, eg.
    %       'net.test' for net-level tests
    root_path = nla.findRootPath();
    subfolders = strsplit(subpackage,'.');
    %First add '+nla' to root_path, and then add each subpackage as folder
    path_to_subfolder = fullfile(root_path,'+nla');
    for i = 1:length(subfolders)
        path_to_subfolder = fullfile(path_to_subfolder, ['+', subfolders{i}]);
    end
    
    network_tests_struct = dir(path_to_subfolder);
    network_test_folder_contents = {network_tests_struct.name};
    network_test_filenames = network_test_folder_contents(~[network_tests_struct.isdir]);

    tests = {};
    for i = 1:numel(network_test_filenames)
        filename_split = split(network_test_filenames{i}, '.');
        if numel(filename_split) == 2 && strcmp(filename_split{2}, 'm')
            test_name = [subpackage '.' filename_split{1}];
            tests{end + 1} = nla.(test_name);
        end
    end
end

