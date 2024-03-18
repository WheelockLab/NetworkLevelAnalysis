import nla.TriMatrix
root_path = nla.findRootPath();
tests = nla.TestPool();
tests.edge_test = nla.edge.test.Precalculated();
tests.net_tests = nla.genTests('net.test');
tests.net_tests = tests.net_tests([4,6,7]);
% Atlas
network_atlas_path = [root_path 'support_files/Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat'];
network_atlas = load(network_atlas_path);
network_atlas = nla.NetworkAtlas(network_atlas);
% Input Struct
input_struct.net_atlas = network_atlas;
input_struct.prob_max = 0.05;
input_struct.permute_method = nla.edge.permutationMethods.None();
input_struct.coeff_min = -3; %AS - changed from -2 to -3
input_struct.coeff_max = 3; %AS - changed from 2 to 3
% Do SIM
path = '/data/wheelock/data1/people/Ari/NLA_Ari/NLA_Output/SIM_output/230829_allSNR_realPerm/';
file = '230829_SIM__SIM_True_mean0.13_sd0.156_Bkgrnd_mean0.00_sd0.146__10000_0.05_IM_Seitzman_15nets_288ROI.mat';
inputs = load([path,file]);
%get data as its own variables
precalc_obs_unordered = inputs.dataIn.fcBx;
precalc_perm_unordered = inputs.dataIn.fcBx_perm;
%make obs coeff structures
input_struct.precalc_obs_coeff = TriMatrix(precalc_obs_unordered);
input_struct.precalc_obs_p = TriMatrix(network_atlas.numROIs);
%make perm coeff structures
input_struct.precalc_perm_coeff = TriMatrix(network_atlas.numROIs); %do this bc its permuted 
input_struct.precalc_perm_coeff.v = precalc_perm_unordered;
input_struct.precalc_perm_p = TriMatrix(network_atlas.numROIs);

%Obs
Nsubs = 50;
rho = input_struct.precalc_obs_coeff.v;
t = (rho.*sqrt(Nsubs-2)).*(sqrt(1-(rho.^2))).^-1; %two sample t distribution
pval0i = 2*tcdf(-abs(t), Nsubs-2);
pval0=+(pval0i<=input_struct.prob_max);
input_struct.precalc_obs_p.v = pval0;
%perm
permrho_matrix = input_struct.precalc_perm_coeff.v;
t = (permrho_matrix.*sqrt(Nsubs-2)).*(sqrt(1-(permrho_matrix.^2))).^-1; %two sample t distribution
permP_matrix = 2*tcdf(-abs(t), Nsubs-2);
pval=+(permP_matrix<=input_struct.prob_max);
input_struct.precalc_perm_coeff.v = permrho_matrix;
input_struct.precalc_perm_p.v = pval;
%Network input struct
network_input_struct = nla.net.genBaseInputs();
network_input_struct.prob_max = 0.05;
network_input_struct.behavior_count = 1;
network_input_struct.d_max = 0.5;
network_input_struct.prob_plot_method = nla.gfx.ProbPlotMethod.DEFAULT;
edge_result_nonperm = tests.runEdgeTest(input_struct);
net_results_nonperm = tests.runNetTests(input_struct, edge_result_nonperm, network_atlas);
edge_result_perm = tests.runEdgeTestPerm(input_struct, 10000, false);
net_results_perm = tests.runNetTestsPerm(network_input_struct, network_atlas, edge_result_perm);
rankings = tests.rankResults(input_struct, net_results_nonperm, net_results_perm, network_atlas.numNetPairs());