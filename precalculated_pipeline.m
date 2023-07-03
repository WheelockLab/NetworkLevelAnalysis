import nla.*

%% Get path to NLA
root_path = findRootPath();

%% Create a pool of tests
tests = TestPool();
tests.net_tests = genTests([root_path '+nla/+net/+test'], 'nla.net.test.');
tests.edge_test = edge.test.Precalculated();

%% Load network atlas
net_atlas_path = [root_path 'support_files/Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat']; % path to network atlas
net_atlas = NetworkAtlas(net_atlas_path);

%% Load precalculated data
% Coefficient range
% !!WARNING!! This should specify the range of the coefficient you are
% using. It is set to -2, 2 as that is the range of the beta weights used
% in the example, but if you are using another coefficient then you should
% set these variables to the corresponding range (-1 and 1 for Pearson r
% values, for example)
input_struct.coeff_min = -2;
input_struct.coeff_max = 2;

% load files
obs_p_file = load('examples/precalculated/SIM_obs_p.mat');
input_struct.precalc_obs_p = TriMatrix(net_atlas.numROIs);
input_struct.precalc_obs_p.v = obs_p_file.SIM_obs_p;

obs_coeff_file = load('examples/precalculated/SIM_obs_coeff.mat');
input_struct.precalc_obs_coeff = TriMatrix(net_atlas.numROIs);
input_struct.precalc_obs_coeff.v = obs_coeff_file.SIM_obs_coeff;

perm_p_file = load('examples/precalculated/SIM_perm_p.mat');
input_struct.precalc_perm_p = TriMatrix(net_atlas.numROIs);
input_struct.precalc_perm_p.v = perm_p_file.SIM_perm_p;

perm_coeff_file = load('examples/precalculated/SIM_perm_coeff.mat');
input_struct.precalc_perm_coeff = TriMatrix(net_atlas.numROIs);
input_struct.precalc_perm_coeff.v = perm_coeff_file.SIM_perm_coeff;

num_perms = size(input_struct.precalc_perm_p.v, 2);

%% Other params
input_struct.net_atlas = net_atlas;
input_struct.prob_max = 0.05;
input_struct.permute_method = nla.permutemethods.None();

net_input_struct = genBaseNetInputs();
net_input_struct.prob_max = 0.05;
net_input_struct.behavior_count = 1;
net_input_struct.d_max = 0.5;
net_input_struct.prob_plot_method = gfx.ProbPlotMethod.DEFAULT;

%% Run tests
edge_result = tests.runEdgeTest(input_struct);
net_results = tests.runNetTests(net_input_struct, edge_result, net_atlas, false);

% Run test pool over the given permutations
results = tests.runPerm(input_struct, net_input_struct, net_atlas, edge_result, net_results, num_perms);

%% Visualize results
results.output();
