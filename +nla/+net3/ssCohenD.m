function d_val = ssCohensD(coeff_net, coeff_all)
    d_val = abs(mean(coeff_net)) / std(coeff_net);
end

