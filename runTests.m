import matlab.unittest.TestSuite
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoverageReport

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

% runner = testrunner("textoutput");
% report_format = CoverReport("coverageReport");
% plugin = CodeCoveragePlugin.forFolder(".", "Producing", report_format);
% runner.addPlugin(plugin);

% results = runner.run(test_suite);
run(test_suite);