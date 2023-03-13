function net_input_struct = adjustProbThresh(net_input_struct)
    %ADJUSTPROBTHRESH Adjust p-value threshold
    if ~isfield(net_input_struct, 'prob_max_original')
        net_input_struct.prob_max_original = net_input_struct.prob_max;
    end
    
    net_input_struct.prob_max = net_input_struct.prob_max_original / net_input_struct.behavior_count;
end

