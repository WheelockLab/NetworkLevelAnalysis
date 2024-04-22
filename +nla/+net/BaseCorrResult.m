classdef BaseCorrResult < nla.net.BaseResult
    properties (Constant)
        has_within_net_pair = true
    end
    
    properties
        d
        within_np_d
    end
    
    methods (Static)
        function inputs = tweakableInputs()
            % Inputs that can be tweaked post-run (ie: are simple
            % thresholds etc. for summary statistics, or generally can be
            % modified without requiring re-permutation)
            inputs = tweakableInputs@nla.net.BasePermResult();
            inputs{end + 1} = nla.inputField.Number('d_max', "Net-level Cohen's D threshold >", 0, 0.5, 1);
        end
    end
    
    methods
        function obj = BaseCorrResult(size)
            import nla.TriMatrix nla.TriMatrixDiag

            obj@nla.net.BaseResult(size);
            
            % Cohen's D-values (used for thresholding in visualizations)
            obj.d = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
            obj.within_np_d = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            merge@nla.net.BaseResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
            
            % Cohen's D-values (used for thresholding in visualizations)
            [obj.d, obj.within_np_d] = nla.net.test.CohenD.effectSizes(edge_result_nonperm, net_atlas);
        end
        
        function output(obj, edge_input_struct, input_struct, net_atlas, edge_result, flags)
            import nla.TriMatrix nla.TriMatrixDiag

            output@nla.net.BaseResult(obj, edge_input_struct, input_struct, net_atlas, edge_result, flags);
            
            if obj.perm_count > 0
                if isfield(flags, 'show_full_conn') && flags.show_full_conn
                    d_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    d_sig.v = (obj.d.v >= input_struct.d_max);
                    
                    name_label = sprintf('Full Connectome Method\nNetwork vs. Connectome Significance');
                    name_label_thresh = sprintf('%s (D > %g)', name_label, input_struct.d_max);
                    if flags.plot_type == nla.PlotType.FIGURE
                        fig = nla.gfx.createFigure(1200, 900);

                        %% Histogram of probabilities, with thresholds markedx
                        obj.plotProbHist(subplot(2,3,4), input_struct.prob_max);

                        %% Check that network-pair size is not a confound
                        obj.plotProbVsNetSize(net_atlas, subplot(2,3,5));
                        obj.plotPermProbVsNetSize(net_atlas, subplot(2,3,6));

                        %% Matrix with significant networks marked
                        [w, ~] = obj.plotProb(edge_input_struct, input_struct, net_atlas, fig, 75, 425,...
                            obj.perm_prob_ew, false, name_label, nla.net.mcc.None(), nla.Method.FULL_CONN, edge_result);
                        obj.plotProb(edge_input_struct, input_struct, net_atlas, fig, w + 50, 425, obj.perm_prob_ew,...
                            d_sig, name_label_thresh, nla.net.mcc.None(), nla.Method.FULL_CONN, edge_result);
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        d_thresh = false;
                        chord_label = name_label;
                        if isfield(input_struct, 'd_thresh_chord_plot') && input_struct.d_thresh_chord_plot
                            d_thresh = d_sig;
                            chord_label = name_label_thresh;
                        end
                        obj.plotChord(edge_input_struct, input_struct, net_atlas, obj.perm_prob_ew, d_thresh,...
                            chord_label, nla.net.mcc.None(), nla.Method.FULL_CONN, edge_result, flags.plot_type);
                    end
                end
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    within_np_d_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    within_np_d_sig.v = (obj.within_np_d.v >= input_struct.d_max);
                    name_label = sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair (D > %g)', input_struct.d_max);
                        
                    if flags.plot_type == nla.PlotType.FIGURE
                        %% Within Net-Pair statistics (withinNP)
                        fig = nla.gfx.createFigure(1000, 900);

                        obj.plotWithinNetPairProbVsNetSize(net_atlas, subplot(2,2,3));
                        [w, ~] = obj.plotProb(edge_input_struct, input_struct, net_atlas, fig, 25, 425,...
                            obj.within_np_prob, false, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'),...
                            input_struct.fdr_correction, nla.Method.WITHIN_NET_PAIR, edge_result);
                        obj.plotProb(edge_input_struct, input_struct, net_atlas, fig, w - 50, 425, obj.within_np_prob,...
                            within_np_d_sig, name_label, input_struct.fdr_correction, nla.Method.WITHIN_NET_PAIR, edge_result);

                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        
                        obj.plotChord(edge_input_struct, input_struct, net_atlas, obj.within_np_prob, within_np_d_sig,...
                            name_label, input_struct.fdr_correction, nla.Method.WITHIN_NET_PAIR, edge_result, flags.plot_type);
                    end
                end
            end
        end
    end
end