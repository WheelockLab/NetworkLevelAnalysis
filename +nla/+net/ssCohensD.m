function d_val = ssCohensD(coeff_net, coeff_all)
    % old method
    %d_val = abs((mean(coeff_net) - mean(coeff_all)) / sqrt(((std(coeff_net) .^ 2) + (std(coeff_all) .^ 2)) / 2));
    d_val = abs(mean(coeff_net)) / std(coeff_net);
end

