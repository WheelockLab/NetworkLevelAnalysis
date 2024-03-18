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

                plot_matrix = obj.perm_prob_ew;
                if input_struct.prob_plot_method == nla.gfx.ProbPlotMethod.STATISTIC
                    plot_matrix = obj.perm_stat_ew;
                end

                if isfield(flags, 'show_full_conn') && flags.show_full_conn
                    if flags.plot_type == nla.PlotType.FIGURE
                        fig = gfx.createFigure(1000, 900);

                        %% Histogram of probabilities, with thresholds marked
                        obj.plotProbHist(subplot(2,2,2), input_struct.prob_max);

                        %% Check that network-pair size is not a confound
                        obj.plotProbVsNetSize(net_atlas, subplot(2,2,3));
                        obj.plotPermProbVsNetSize(net_atlas, subplot(2,2,4));

                        %% Matrix with significant networks marked
                        obj.plotProb(edge_input_struct, input_struct, net_atlas, fig, 25, 425, plot_matrix, false, sprintf('Full Connectome Method\nNetwork vs. Connectome Significance'), net.mcc.None(), nla.Method.FULL_CONN, edge_result);
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.plotChord(edge_input_struct, input_struct, net_atlas, plot_matrix, false, sprintf('Full Connectome Method\nNetwork vs. Connectome Significance'), net.mcc.None(), nla.Method.FULL_CONN, edge_result, flags.plot_type);
                    end
                end
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    if flags.plot_type == nla.PlotType.FIGURE
                        %% Within Net-Pair statistics (withinNP)
                        fig = gfx.createFigure(500, 900);
                        obj.plotWithinNetPairProbVsNetSize(net_atlas, subplot(2,1,2));
                        obj.plotProb(edge_input_struct, input_struct, net_atlas, fig, 0, 425, plot_matrix, false, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'), input_struct.fdr_correction, nla.Method.WITHIN_NET_PAIR, edge_result);
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.plotChord(edge_input_struct, input_struct, net_atlas, plot_matrix, false, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'), input_struct.fdr_correction, nla.Method.WITHIN_NET_PAIR, edge_result, flags.plot_type);
                    end
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