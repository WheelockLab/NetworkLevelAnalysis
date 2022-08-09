import nla.*

%% Get path to NLA
root_path = findRootPath();

%% Create a pool of tests
tests = TestPool();
tests.net_tests = genTests([root_path '+nla/+net/+test'], 'nla.net.test.');

% Example: Changing the edge-level test
% tests.edge_test = edge.test.Spearman(0.05);
% tests.edge_test = edge.test.SpearmanEstimator(0.05);
% tests.edge_test = edge.test.Pearson(0.05);
% tests.edge_test = edge.test.Kendall(0.05);
% tests.edge_test = edge.test.KendallEstimator(0.05); %TODO unfinished don't use
% tests.edge_test = edge.test.WelchT(0.05); % requires boolean 'in/outgroup' vector to be passed in as behavior

% Example: Appending another net-level test
% tests.net_tests{end + 1} = net.test.ChiSquared(0.05);

% Example: Using a certain pool of net-level tests
% tests.net_tests = {net.test.ChiSquared(0.05) net.test.HyperGeo(0.05)};

%% Load network atlas
net_atlas = NetworkAtlas('# Path to network atlas here #');

%% Load functional connectivity matrix
% load your FC matrix here
fc_unordered = 

% functional connectivity matrix (not ordered/trimmed according to network atlas yet)
func_conn_unordered = double(fc_unordered);

%% Transform R-values to Z-scores
% If this condition isn't true, it cannot be R values
% If it is true, it is almost certainly R values but might not be
if all(abs(func_conn_unordered(:)) <= 1)
    func_conn_unordered = fisherR2Z(func_conn_unordered);
end

%% Arrange network according to the network atlas
input_struct.func_conn = TriMatrix(func_conn_unordered(net_atlas.ROI_order, net_atlas.ROI_order, :));

%% Load behavior
%load your behavioral vector here
input_struct.behavior = 
% Example of setting group names and associated values, when using the
% 2-group Welch's T as your edge-level test
%input_struct.group1_name = 'F';
%input_struct.group1_val = 0;
%input_struct.group2_name = 'M';
%input_struct.group2_val = 1;

%% Other params
input_struct.prob_max = 0.05;

net_input_struct.prob_max = 0.05;
net_input_struct.behavior_count = 1;
net_input_struct.d_max = 0.5;
net_input_struct.log_plot_prob = false;

%% Partial variance
% covariates = NxM matrix of covariates to factor from behavioral scores/fc
% where N is the number of subjects and M is the # of covariate columns
%[input_struct.func_conn, input_struct.behavior] = partialVariance(input_struct.func_conn, input_struct.behavior, covariates, PartialVarianceType.FCBX);

%% Clean up unnecessary variables
clear fc_unordered fc_struct bx

%% Load cortex anatomy
% Pick which one of these to use based on your network atlas, TT or MNI
%anat = CortexAnatomy('support_files/meshes/MNI_32k.mat');
%anat = CortexAnatomy('support_files/meshes/Conte69_32k_on_TT.mat');

%% Visualize average functional connectivity values
fc_avg = copy(input_struct.func_conn);
fc_avg.v = mean(fc_avg.v, 2);
fig_l = figure('Color', 'w');
[fig_l.Position(3), fig_l.Position(4)] = gfx.drawMatrixOrg(fig_l, 0, 0,  'FC Average', fc_avg, -0.3, 0.3, net_atlas.nets, gfx.FigSize.LARGE, gfx.FigMargins.WHITESPACE, true, true);
drawnow();

%% Visualize network/ROI locations
gfx.drawNetworkROIs(net_atlas, anat, gfx.MeshType.STD, 0.8, 4, false);
%gfx.drawNetworkROIs(net_atlas, anat, gfx.MeshType.STD, 1, 4, true);
drawnow();

%% Run tests
edge_result = tests.runEdgeTest(input_struct, false);
net_results = tests.runNetTests(net_input_struct, edge_result, net_atlas, false);

% Run test pool, permuting data n times
results = tests.runPerm(input_struct, net_input_struct, net_atlas, edge_result, net_results, 100);

%% Visualize results
results.output();
