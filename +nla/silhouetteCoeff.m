function [si_vals] = silhouetteCoeff(fc_avg, networks)
    %SILHOUETTECOEFF Calculate silhouette coefficient
    %   fc_avg: TriMatrix of average functional connectivity values
    %   networks: Vector of objects which must implement IndexGroup, ie:
    %       have a name, color, and a vector of indices corresponding to
    %       data in the input matrix
    %   si_vals: 1xNrois vector of silhouette values
    
    % tweak fc to fit the input format demanded by lib.calc_correlationdist
    fc_mat = fc_avg.asMatrix();
    fc_mat(isnan(fc_mat)) = 0;
    fc_mat = fc_mat + fc_mat';
    
    % only include ROIs which are indexed in given nets
    included_ROIs = vertcat(networks.indexes);
    fc_included = fc_mat(included_ROIs, included_ROIs);
    
    % vector mapping ROIs to networks, like ROI_key
    ROI_keys_kept = [];
    for i = 1:numel(networks)
        ROI_keys_kept = [ROI_keys_kept;repelem(i,networks(i).numROIs())'];
    end
    
    % calculating correlation distance pairwise by ignoring the diagonals
    corr_distance = nla.lib.calc_correlationdist(fc_included);
    
    % all networks are connected to all other networks, but no self-pairing
    net_pair_connected = true(numel(networks));
    net_pair_connected = net_pair_connected - diag(diag(net_pair_connected));
    
    %% Calculate silhouette values
    si_vals = nla.lib.silhouette_mod(ROI_keys_kept, corr_distance, net_pair_connected);
end

