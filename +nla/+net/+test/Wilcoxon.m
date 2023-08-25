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
                    within_np_d_val = net.ssCohensD(coeff_net, edge_result.coeff.v);
                    within_np_d.set(row, col, within_np_d_val);
                end
            end
            
            % if a previous result is passed in, add on to it
            if previous_result ~= false
                result = obj.rank(net_atlas, previous_result, input_struct, @helpers.abs_ge, previous_result.z, previous_result.prob, z, prob, previous_result.ss_w, previous_result.ss_prob, ss_w, ss_prob);
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

