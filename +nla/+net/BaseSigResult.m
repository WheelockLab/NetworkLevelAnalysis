classdef BaseSigResult < nla.net.BaseResult
    properties (Constant)
        has_within_net_pair = true
    end
    
    properties
        observed_gt_expected
    end
        
    methods
        function obj = BaseSigResult(size)
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseResult(size);
            
            obj.observed_gt_expected = TriMatrix(size, 'logical', TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function output(obj, input_struct, net_atlas, edge_result, flags)
            import nla.* % required due to matlab package system quirks
            output@nla.net.BaseResult(obj, input_struct, net_atlas, edge_result, flags);
            
            if obj.perm_count > 0
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    within_np_prob_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    within_np_prob_sig.v = obj.within_np_prob.v < input_struct.prob_max / net_atlas.numNetPairs();
                    if flags.plot_type == nla.PlotType.FIGURE
                        %% Within Net-Pair statistics (withinNP)
                        fig = gfx.createFigure(500, 900);
                        obj.plotWithinNetPairProbVsNetSize(net_atlas, subplot(2,1,2));
                        obj.plotProb(input_struct, net_atlas, fig, 0, 425, obj.within_np_prob, within_np_prob_sig, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'), true, nla.Method.WITHIN_NET_PAIR);
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.plotChord(input_struct, net_atlas, obj.within_np_prob, within_np_prob_sig, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'), true, nla.Method.WITHIN_NET_PAIR, edge_result, flags.plot_type);
                    end
                end
            end
        end
        
        function [num_tests, sig_count_mat, names] = getSigMat(obj, input_struct, net_atlas, flags)
            import nla.* % required due to matlab package system quirks
            [num_tests, sig_count_mat, names] = getSigMat@nla.net.BaseResult(obj, input_struct, net_atlas, flags);
            if obj.perm_count > 0
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    num_tests = num_tests + 1;
                    sig_count_mat.v = sig_count_mat.v + (obj.within_np_prob.v < input_struct.prob_max / net_atlas.numNetPairs());
                    names = [names sprintf("Within Net-Pair %s", obj.name)];
                end
            end
        end
    end
end