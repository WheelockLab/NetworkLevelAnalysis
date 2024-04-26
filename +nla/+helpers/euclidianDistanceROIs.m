function distances = euclidianDistanceROIs(network_atlas)

    pos_vec = [network_atlas.ROIs(1:network_atlas.numROIs()).pos]';
    dist_comp_sum = zeros(network_atlas.numROIs(), network_atlas.numROIs());
    compute_dist_component = @(a, b) (a - b) .^ 2;
    for dim = 1:3
        pos_comp = pos_vec(:, dim);
        dist_comp = bsxfun(compute_dist_component, pos_comp, pos_comp');
        dist_comp_sum = dist_comp_sum + dist_comp;
    end
    dist = sqrt(dist_comp_sum);
    distances = nla.TriMatrix(dist);
end

