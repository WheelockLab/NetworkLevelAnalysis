%% main input data
net_atlas_folder = fullfile(nla.findRootPath(),'support_files');
net_atlas = nla.NetworkAtlas(fullfile(net_atlas_folder, 'Gordon_13nets_333parcels_on_MNI.mat'));

fc_data = rand(333,333,10); %Random FC data

behavior = round(rand(10,1));

%% run settings

edge_input = struct();
edge_input.prob_max = 0.05;
edge_input.permutation_groups = 0;
edge_input.behavior = behavior; 
edge_input.func_conn = nla.TriMatrix(fc_data,'nla.TriMatrixDiag', nla.TriMatrixDiag.KEEP_DIAGONAL);
edge_input.net_atlas = net_atlas;
edge_input.permute_method = nla.edge.permutationMethods.BehaviorVec();

net_input = struct();
net_input.no_permutations = 1;
net_input.full_connectome = 1;
net_input.within_network_pair = 1;
net_input.prob_plot_method = nla.gfx.ProbPlotMethod.DEFAULT;
net_input.edge_chord_plot_method = nla.gfx.ProbPlotMethod.DEFAULT;
net_input.fdr_correction = nla.net.mcc.Bonferroni();
net_input.d_thresh_chord_plot = 1;
net_input.perm_count = 100;
net_input.behavior_count = 1;
net_input.prob_max = 0.0500;

%% Setup Test PoolDefine edge and net tests

test_pool = nla.TestPool();

test_pool.edge_test = nla.edge.test.Spearman();

test_pool.net_tests = {nla.net.test.WilcoxonTest(), nla.net.test.WelchTTest()};

%% Run non-permuted tests

edge_result = test_pool.runEdgeTest(edge_input);

net_results = test_pool.runNetTests(net_input, edge_result, net_atlas, false);

%% Run permutation
num_perms = 100;
perm_seed = false;
separate_network_and_edge_tests = false;

resultsObj = test_pool.runPerm(edge_input, net_input, net_atlas, edge_result,...
            net_results, num_perms, perm_seed, separate_network_and_edge_tests);

%% Plot tri matrix result

wilcoxon_result = resultsObj.network_test_results{1}; %Gets first net result
wilcoxon_fullconn_result = wilcoxon_result.full_connectome; % gets full_conn results for all rankings

resultToPlot = ...
        wilcoxon_fullconn_result.westfall_young_two_sample_p_value;

data_as_mat = resultToPlot.asMatrix();

data_is_sig = data_as_mat < 0.05;

plot_settings = getDefaultPlotSettings();

fig_h = figure();
plotNetTriMatrix(fig_h, net_atlas, data_as_mat, data_is_sig, plot_settings)
