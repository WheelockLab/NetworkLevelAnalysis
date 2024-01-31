import nla.*
import nla.gfx.matrix.*

%% Get path to NLA
root_path = findRootPath();

%% Create a pool of tests
tests = TestPool();
tests.net_tests = genTests('net.test');

% Example: Changing the edge-level test
% tests.edge_test = edge.test.Spearman();
% tests.edge_test = edge.test.SpearmanEstimator();
% tests.edge_test = edge.test.Pearson();
% tests.edge_test = edge.test.KendallB();
% tests.edge_test = edge.test.WelchT(); % requires boolean 'in/outgroup' vector to be passed in as behavior

% Example: Appending another net-level test
% tests.net_tests{end + 1} = net.test.ChiSquared();

% Example: Using a certain pool of net-level tests
% tests.net_tests = {net.test.ChiSquared() net.test.HyperGeo()};

%% Load functional connectivity matrix
% load your FC matrix here
fc_path = [root_path 'examples/fc_and_behavior/sample_func_conn.mat']; % path to fc
fc_struct = load(fc_path);
fc_unordered = fc_struct.fc;

% functional connectivity matrix (not ordered/trimmed according to network atlas yet)
func_conn_unordered = double(fc_unordered);

%% Load network atlas and remove undesired networks (Optional)
net_atlas_path = [root_path 'support_files/Wheelock_2020_CerebralCortex_17nets_300ROI_on_MNI.mat']; % path to network atlas
prev_net_atlas = load(net_atlas_path);
nets_to_remove = ["US"]; % remove the unspecified/none network
[new_net_atlas] = removeNetworks(prev_net_atlas, nets_to_remove, 'Wheelock_2020_CerebralCortex_16nets_288ROI_on_MNI');
net_atlas = NetworkAtlas(new_net_atlas);
%% OR load network atlas without removing networks
% This should be done if your parcellation lacks an "unspecified" network,
% or, if the atlas you are using has already removed it.
%net_atlas_path = [root_path 'support_files/Wheelock_2020_CerebralCortex_16nets_288ROI_on_MNI.mat']; % path to network atlas
%net_atlas = NetworkAtlas(net_atlas_path);

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
bx_path = [root_path 'examples/fc_and_behavior/sample_behavior.mat']; % path to bx
bx_struct = load(bx_path);
bx = bx_struct.Bx;
input_struct.behavior = bx(:, 10).Variables;
% Example of setting group names and associated values, when using the
% 2-group Welch's T as your edge-level test
%input_struct.group1_name = 'F';
%input_struct.group1_val = 0;
%input_struct.group2_name = 'M';
%input_struct.group2_val = 1;

%% Other params
input_struct.net_atlas = net_atlas;
input_struct.prob_max = 0.05;
input_struct.permute_method = nla.edge.permutationMethods.BehaviorVec();

net_input_struct = net.genBaseInputs();
net_input_struct.prob_max = 0.05;
net_input_struct.behavior_count = 1;
net_input_struct.d_max = 0.5;
net_input_struct.prob_plot_method = gfx.ProbPlotMethod.DEFAULT;

%% Partial variance
% covariates = NxM matrix of covariates to factor from behavioral scores/fc
% where N is the number of subjects and M is the # of covariate columns
%[input_struct.func_conn, input_struct.behavior] = partialVariance(input_struct.func_conn, input_struct.behavior, covariates, PartialVarianceType.FCBX);

%% Clean up unnecessary variables
clear fc_unordered fc_struct bx

%% Visualize average functional connectivity values
fc_avg = copy(input_struct.func_conn);
fc_avg.v = mean(fc_avg.v, 2);
fig_l = gfx.createFigure(800, 800);
% [fig_l.Position(3), fig_l.Position(4)] = gfx.drawMatrixOrg(fig_l, 0, 0,  'FC Average', fc_avg, -0.3, 0.3, net_atlas.nets, gfx.FigSize.LARGE, gfx.FigMargins.WHITESPACE, true, true);
obj = MatrixPlot(fig_l, "FC Average", fc_avg, net_atlas.nets, gfx.FigSize.LARGE);
obj.displayImage()
drawnow();

%% Visualize network/ROI locations
gfx.drawNetworkROIs(net_atlas, gfx.MeshType.STD, 0.8, 4, false);
gfx.drawNetworkROIs(net_atlas, gfx.MeshType.STD, 1, 4, true);
drawnow();

%% Run tests
edge_result = tests.runEdgeTest(input_struct);
net_results = tests.runNetTests(net_input_struct, edge_result, net_atlas, false);

% Run test pool, permuting data n times
results = tests.runPerm(input_struct, net_input_struct, net_atlas, edge_result, net_results, 100);

%% Visualize results
% Warning: Will produce a large amount of figures. You are advised to use
% the GUI to visualize results, or to use the output calls of individual
% result objects.
results.output();

%% Save results
% Should be able to visualize this result file by loading it into the GUI
results.to_file('myresults.mat');
