function satisfied = checkInput(input_struct, net_input_struct, fig)
    import nla.* % required due to matlab package system quirks
    %CHECKINPUT Check input structures for errors, producing found errors
    % in string array
    
    %% Check head motion
    if ismember('motion', input_struct.behavior_full.Properties.VariableNames)
        [r_vec, p_vec] = corr(input_struct.behavior_full.motion, input_struct.func_conn.v', 'type', 'Pearson');
        r_median = median(abs(r_vec));
        p_median = median(p_vec);
        
        title = 'Acceptable motion levels?';
        msg = sprintf("Found and correlated 'motion' field with functional connectivity data. There was a median correlation (Pearson's r) of %.2f with a median p-value of %.2f\n\nContinue and run tests?", r_median, p_median);
        sel = uiconfirm(fig, msg, title, 'Options', {DialogOption.YES, DialogOption.CANCEL}, 'DefaultOption', 1, 'CancelOption', 2);
        
        if strcmp(sel, DialogOption.CANCEL)
            satisfied = false;
            return
        end
    end
    
    %% All checks passed, return true
    satisfied = true;
end

