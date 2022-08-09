classdef BaseCorrResult < nla.net.BaseResult
    properties (Constant)
        has_within_net_pair = true
    end
    
    properties
        within_np_d
    end
    
    methods
        function obj = BaseCorrResult(size)
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseResult(size);
            
            %% Within Net-Pair statistics (withinNP)
            obj.within_np_d = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            import nla.* % required due to matlab package system quirks
            merge@nla.net.BaseResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
            
            %% Within Net-Pair statistics (withinNP)
            num_nets = net_atlas.numNets();
            for row = 1:num_nets
                for col = 1:row
                    % get permuted and nonpermuted edge-level coefficients
                    i_row = net_atlas.nets(row).indexes;
                    i_col = net_atlas.nets(col).indexes;
                    coeff_net = edge_result_nonperm.coeff.get(i_row, i_col);
                    coeff_net_perm = edge_result.coeff_perm.get(i_row, i_col);
                    
                    coeff_net_perm = reshape(coeff_net_perm, [], 1);
                    obj.within_np_d.set(row, col, abs((mean(coeff_net) - mean(coeff_net_perm)) / sqrt((std(coeff_net) .^ 2) + (std(coeff_net_perm) .^ 2) / 2)));
                    obj.within_np_prob.set(row, col, obj.withinNetPairOneNet(coeff_net, coeff_net_perm));
                end
            end
        end
        
        function output(obj, input_struct, net_atlas, flags)
            import nla.* % required due to matlab package system quirks
            output@nla.net.BaseResult(obj, input_struct, net_atlas, flags);
            
            if obj.perm_count > 0
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    %% Within Net-Pair statistics (withinNP)
                    fig = gfx.createFigure(1000, 900);

                    obj.plotWithinNetPairProbVsNetSize(net_atlas, subplot(2,2,3));

                    within_np_prob_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    within_np_prob_sig.v = obj.within_np_prob.v < input_struct.prob_max / net_atlas.numNetPairs();
                    [w, ~] = obj.plotProb(input_struct, net_atlas, fig, 25, 425, obj.within_np_prob, within_np_prob_sig, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'), true);

                    within_np_prob_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    within_np_prob_sig.v = (obj.within_np_prob.v < input_struct.prob_max / net_atlas.numNetPairs()) & (obj.within_np_d.v >= input_struct.d_max);
                    name_label = sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair (D > %g)', input_struct.d_max);
                    obj.plotProb(input_struct, net_atlas, fig, w - 50, 425, obj.within_np_prob, within_np_prob_sig, name_label, true);
                end
            end
        end
    end
end