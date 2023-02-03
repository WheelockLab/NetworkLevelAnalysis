classdef Wilcoxon < nla.net.BaseCorrTest
    %WILCOXON Network level Wilcoxon test
    properties (Constant)
        name = "Wilcoxon rank-sum"
    end
    
    methods
        function obj = Wilcoxon()
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseCorrTest();
        end
        
        function result = run(obj, input_struct, edge_result, net_atlas, previous_result)
            import nla.* % required due to matlab package system quirks

            num_nets = net_atlas.numNets();
            
            prob = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            w = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            z = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            ss_prob = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            ss_w = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            within_np_d = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            for row = 1:num_nets
                for col = 1:row
                    coeff_net = edge_result.coeff.get(net_atlas.nets(row).indexes, net_atlas.nets(col).indexes);
                    
                    [p_val, ~, wstat] = ranksum(coeff_net, edge_result.coeff.v);
                    w_val = wstat.ranksum;
                    z_val = wstat.zval;
                    prob.set(row, col, p_val);
                    w.set(row, col, w_val);
                    z.set(row, col, z_val);
                    
                    [ss_val, ~, ss_stats] = signrank(coeff_net);
                    ss_w_val = ss_stats.signedrank;
                    ss_prob.set(row, col, ss_val);
                    ss_w.set(row, col, ss_w_val);
                    
                    % Cohen's D, needed in within net-pair figures
                    within_np_d_val = abs((mean(coeff_net) - mean(edge_result.coeff.v)) / sqrt(((std(coeff_net) .^ 2) + (std(edge_result.coeff.v) .^ 2)) / 2));
                    within_np_d.set(row, col, within_np_d_val);
                end
            end
            
            % if a previous result is passed in, add on to it
            if previous_result ~= false
                result = previous_result;
                
                % rank either test statistic or p-values
                if ~isfield(input_struct, 'ranking_method') || input_struct.ranking_method == RankingMethod.TEST_STATISTIC
                    sig_gt_nonpermuted = abs(z.v) >= abs(result.z.v);
                    ss_sig_gt_nonpermuted = ss_w.v >= result.ss_w.v;
                else
                    sig_gt_nonpermuted = prob.v <= result.prob.v;
                    ss_sig_gt_nonpermuted = ss_prob.v <= result.ss_prob.v;
                end
                result.perm_rank.v = result.perm_rank.v + uint64(sig_gt_nonpermuted);
                result.within_np_rank.v = result.within_np_rank.v + uint64(ss_sig_gt_nonpermuted);
                
                for i = 1:net_atlas.numNetPairs()
                    % Similar to the previous ranking, but experiment-wide
                    % Code is subtly different from previous usage, 
                    % refactor with care.
                    if ~isfield(input_struct, 'ranking_method') || input_struct.ranking_method == RankingMethod.TEST_STATISTIC
                        sig_gt_nonpermuted = abs(z.v) >= abs(result.z.v(i));
                    else
                        sig_gt_nonpermuted = prob.v <= result.prob.v(i);
                    end
                    result.perm_rank_ew.v(i) = result.perm_rank_ew.v(i) + sum(uint64(sig_gt_nonpermuted));
                end
                
                result.perm_prob_hist = result.perm_prob_hist + uint32(histcounts(prob.v, HistBin.EDGES)');
                result.perm_count = result.perm_count + 1;
            else
                result = net.result.Wilcoxon(num_nets);
                result.prob = prob;
                result.w = w;
                result.z = z;
                result.ss_prob = ss_prob;
                result.ss_w = ss_w;
                result.within_np_d = within_np_d;
            end
        end
    end
end

