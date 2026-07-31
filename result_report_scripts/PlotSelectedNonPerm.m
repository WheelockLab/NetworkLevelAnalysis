function PlotSelectedNonPerm(inArg)
    % inArg will be a struct with 2 fields:
    % net_result is the net_result object selected by the user in the
    % NLA_Result window
    % test_method is the type of test (no_permutations, full_connectome, within_network_pair)
    % net pair) of the selected test.
    
    plot_settings = nla.gfx.plotfunctions.getDefaultPlotSettings();
    
    
    for i = 1:length(inArg.selected_results)   
        this_selected_result_node = inArg.selected_results{i};
        
        net_result = this_selected_result_node.net_result;
        test_method = this_selected_result_node.test_method;
        
        plot_settings.plot_max = net_result.test_options.prob_max;
        
        if ~strcmpi(test_method,'no_permutations')
            continue;
        end                
        
        % SELECT THE RANKING METHOD, AND WHETHER YOU WANT SINGLE OR TWO SAMPLE P VALUE
        p_value_type = 'uncorrected'; %{'freedman_lane', 'westfall_young', 'uncorrected'}
        sample_type = 'two_sample'; %{'single_sample', 'two_sample'} %fullconn is always two_sample, within_net_pair is always single_sample
                
        prob_field_name = [p_value_type,'_',sample_type,'_','p_value'];
        
        if ~isfield(net_result.(test_method),prob_field_name)
            msgbox(sprintf('%s does no contain %s type results. Skipping test.', ...
                net_result.test_display_name, [p_value_type,'_',sample_type]));
            continue;
        end
                
        net_result_tri_matrix = ...
                net_result.(test_method).(prob_field_name);

        data_as_mat = net_result_tri_matrix.asMatrix();

        data_is_sig = data_as_mat < net_result.test_options.prob_max;        

        fig_h = figure();
        nla.gfx.plotfunctions.plotNetTriMatrix(fig_h, inArg.net_atlas, data_as_mat, data_is_sig, plot_settings);
    end
    
    
    
end