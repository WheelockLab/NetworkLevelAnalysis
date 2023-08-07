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
        
        function output(obj, edge_input_struct, input_struct, net_atlas, edge_result, flags)
            import nla.* % required due to matlab package system quirks
            output@nla.net.BaseResult(obj, edge_input_struct, input_struct, net_atlas, edge_result, flags);
            
            if obj.perm_count > 0
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    if flags.plot_type == nla.PlotType.FIGURE
                        %% Within Net-Pair statistics (withinNP)
                        fig = gfx.createFigure(500, 900);
                        obj.plotWithinNetPairProbVsNetSize(net_atlas, subplot(2,1,2));
                        obj.plotProb(input_struct, net_atlas, fig, 0, 425, obj.within_np_prob, false, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'), net.correctFDR.None(), nla.Method.WITHIN_NET_PAIR);
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.plotChord(edge_input_struct, input_struct, net_atlas, obj.within_np_prob, false, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'), net.correctFDR.None(), nla.Method.WITHIN_NET_PAIR, edge_result, flags.plot_type);
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
                    
                    p_max = net.correctFDR.None.correct(net_atlas, input_struct, obj.within_np_prob);
                    p_breakdown_label = net.correctFDR.None.createLabel(net_atlas, input_struct, obj.within_np_prob);
                    
                    sig_count_mat.v = sig_count_mat.v + (obj.within_np_prob.v < p_max);
                    names = [names sprintf("Within Net-Pair %s P < %.2g (%s)", obj.name, p_max, p_breakdown_label)];
                end
            end
        end
    end
    
    methods (Access = protected)
        function genChordPlotFig(obj, edge_input_struct, input_struct, net_atlas, edge_result, plot_sig, plot_mat, plot_max, cm, name_label, sig_increasing, chord_type)
            edge_result_thresh = copy(edge_result);
            edge_result_thresh.coeff.v(edge_result_thresh.prob_sig.v == 0) = 0;
            genChordPlotFig@nla.net.BaseResult(obj, edge_input_struct, input_struct, net_atlas, edge_result_thresh, plot_sig, plot_mat, plot_max, cm, name_label, sig_increasing, chord_type)
        end
    end
end