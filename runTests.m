import matlab.unittest.TestSuite

root_path = nla.findRootPath();

% get all unittests folders
filelist = dir(fullfile(root_path, '**/unittests'));

% make cell array with extra check on if directory
test_folders = {filelist([filelist.isdir]).folder};

test_folders = convertCharsToStrings(unique(test_folders));

test_suite = TestSuite.fromFolder(test_folders(1));

for folder = 2:numel(test_folders)
    test_suite = [test_suite TestSuite.fromFolder(test_folders(folder))];
end

test_results = run(test_suite);