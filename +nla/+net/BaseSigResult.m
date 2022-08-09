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
        
        function output(obj, input_struct, net_atlas, flags)
            import nla.* % required due to matlab package system quirks
            output@nla.net.BaseResult(obj, input_struct, net_atlas, flags);
            
            if obj.perm_count > 0
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    %% Within Net-Pair statistics (withinNP)
                    fig = gfx.createFigure(500, 900);

                    obj.plotWithinNetPairProbVsNetSize(net_atlas, subplot(2,1,2));

                    within_np_prob_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    within_np_prob_sig.v = obj.within_np_prob.v < input_struct.prob_max / net_atlas.numNetPairs();
                    obj.plotProb(input_struct, net_atlas, fig, 0, 425, obj.within_np_prob, within_np_prob_sig, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'), true);
                end
            end
        end
    end
end