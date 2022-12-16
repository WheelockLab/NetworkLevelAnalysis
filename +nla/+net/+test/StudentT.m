classdef StudentT < nla.net.BaseCorrTest
    %WELCHT Network level Welch T-test
    properties (Constant)
        name = "Student's T"
    end
    
    methods
        function obj = StudentT()
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseCorrTest();
        end
        
        function result = run(obj, input_struct, edge_result, net_atlas, previous_result)
            import nla.* % required due to matlab package system quirks

            num_nets = net_atlas.numNets();
            
            prob = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            t = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            for row = 1:num_nets
                for col = 1:row
                    coeff_net = edge_result.coeff.get(net_atlas.nets(row).indexes, net_atlas.nets(col).indexes);
                    
                    [~, p_val, ~, stats] = ttest2(coeff_net, edge_result.coeff.v);
                    t_val = stats.tstat;
                    
                    prob.set(row, col, p_val);
                    t.set(row, col, t_val);
                end
            end
            
            % if a previous result is passed in, add on to it
            if previous_result ~= false
                result = previous_result;
                
                % rank either test statistic or p-values
                if ~isfield(input_struct, 'ranking_method') || input_struct.ranking_method == RankingMethod.TEST_STATISTIC
                    sig_gt_nonpermuted = abs(t.v) >= abs(result.t.v);
                else
                    sig_gt_nonpermuted = prob.v <= result.prob.v;
                end
                result.perm_rank.v = result.perm_rank.v + uint64(sig_gt_nonpermuted);
                
                for i = 1:net_atlas.numNetPairs()
                    % Similar to the previous ranking, but experiment-wide
                    % Code is subtly different from previous usage, 
                    % refactor with care.
                    if ~isfield(input_struct, 'ranking_method') || input_struct.ranking_method == RankingMethod.TEST_STATISTIC
                        sig_gt_nonpermuted = abs(t.v) >= abs(result.t.v(i));
                    else
                        sig_gt_nonpermuted = prob.v <= result.prob.v(i);
                    end
                    result.perm_rank_ew.v(i) = result.perm_rank_ew.v(i) + sum(uint64(sig_gt_nonpermuted));
                end
                
                result.perm_prob_hist = result.perm_prob_hist + uint32(histcounts(prob.v, HistBin.EDGES)');
                result.perm_count = result.perm_count + 1;
            else
                result = net.result.StudentT(num_nets);
                result.prob = prob;
                result.t = t;
            end
        end
    end
end

