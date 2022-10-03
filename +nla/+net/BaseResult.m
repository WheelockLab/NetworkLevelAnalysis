classdef BaseResult < nla.net.BasePermResult
    %BASERESULT Base class of results of net-level analysis
    properties (Constant)
        has_full_conn = true
        has_nonpermuted = true
    end
    
    properties
        prob
        perm_prob_hist
        empirical_fdr
        prob_max_ew = NaN
        within_np_prob
    end
    
    methods
        function obj = BaseResult(size)
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BasePermResult(size);
            
            % non-permuted stats
            obj.prob = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);

            % permuted stats
            obj.perm_prob_hist = zeros(HistBin.SIZE, 'uint32');
            obj.empirical_fdr = zeros(HistBin.SIZE);
            
            %% Within Net-Pair (withinNP)
            obj.within_np_prob = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function output(obj, input_struct, net_atlas, edge_result, flags)
            import nla.* % required due to matlab package system quirks
            if obj.perm_count > 0
                if isfield(flags, 'show_full_conn') && flags.show_full_conn
                    perm_prob_ew_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    perm_prob_ew_sig.v = obj.perm_prob_ew.v < input_struct.prob_max;
                    
                    if flags.plot_type == nla.PlotType.FIGURE
                        fig = gfx.createFigure(1000, 900);

                        %% Histogram of probabilities, with thresholds marked
                        ax = subplot(2,2,2);
                        loglog(HistBin.EDGES(2:end), obj.empirical_fdr, 'k');
                        hold('on');
                        loglog(obj.prob.v, obj.perm_prob_ew.v, 'ok');
                        axis([min(obj.prob.v), 1, min(obj.perm_prob_ew.v), 1])            
                        loglog(ax.XLim, [input_struct.prob_max, input_struct.prob_max], 'b');
                        loglog([obj.prob_max_ew, obj.prob_max_ew], ax.YLim, 'r')

                        name_label = sprintf("%s P-values", obj.name_formatted);
                        title(name_label);
                        xlabel('Asymptotic');
                        ylabel('Permutation-based P-value');

                        %% Check that network-pair size is not a confound
                        obj.plotProbVsNetSize(net_atlas, subplot(2,2,3));
                        obj.plotPermProbVsNetSize(net_atlas, subplot(2,2,4));

                        %% Matrix with significant networks marked
                        obj.plotProb(input_struct, net_atlas, fig, 25, 425, obj.perm_prob_ew, perm_prob_ew_sig, sprintf('Full Connectome Method\nNetwork vs. Connectome Significance'), false, nla.Method.FULL_CONN);
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.plotChord(input_struct, net_atlas, obj.perm_prob_ew, perm_prob_ew_sig, sprintf('Full Connectome Method\nNetwork vs. Connectome Significance'), false, nla.Method.FULL_CONN, edge_result, flags.plot_type);
                    end
                end
            else
                if isfield(flags, 'show_nonpermuted') && flags.show_nonpermuted
                    prob_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    prob_sig.v = obj.prob.v < input_struct.prob_max / net_atlas.numNetPairs();
                        
                    if flags.plot_type == nla.PlotType.FIGURE
                        %% Non-permuted
                        fig = gfx.createFigure(500, 900);

                        %% Check that network-pair size is not a confound
                        obj.plotProbVsNetSize(net_atlas, subplot(2,1,2));

                        %% Matrix with significant networks marked
                        obj.plotProb(input_struct, net_atlas, fig, 0, 425, obj.prob, prob_sig, sprintf('Non-permuted Method\nNon-permuted Significance'), true, nla.Method.NONPERMUTED);
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.plotChord(input_struct, net_atlas, obj.prob, prob_sig, sprintf('Non-permuted Method\nNon-permuted Significance'), true, nla.Method.NONPERMUTED, edge_result, flags.plot_type);
                    end
                end
            end
        end
        
        function [num_tests, sig_count_mat, names] = getSigMat(obj, input_struct, net_atlas, flags)
            import nla.* % required due to matlab package system quirks
            num_tests = 0;
            sig_count_mat = TriMatrix(net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
            names = [];
            
            if obj.perm_count > 0
                if isfield(flags, 'show_full_conn') && flags.show_full_conn
                    num_tests = num_tests + 1;
                    sig_count_mat.v = sig_count_mat.v + (obj.perm_prob_ew.v < input_struct.prob_max);
                    names = [names sprintf("Full Connectome %s", obj.name)];
                end
            else
                if isfield(flags, 'show_nonpermuted') && flags.show_nonpermuted
                    num_tests = num_tests + 1;
                    sig_count_mat.v = sig_count_mat.v + (obj.prob.v < input_struct.prob_max / net_atlas.numNetPairs());
                    names = [names sprintf("Non-Permuted %s", obj.name)];
                end
            end
        end
        
        % merged is a function which merges 2 results from the same test
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            import nla.* % required due to matlab package system quirks
            merge@nla.net.BasePermResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
            
            % Empirical FDR
            for j = 1:numel(results)
                obj.perm_prob_hist = obj.perm_prob_hist + results{j}.perm_prob_hist;
            end
            obj.empirical_fdr = cumsum(double(obj.perm_prob_hist) ./ sum(obj.perm_prob_hist));
            [~, min_idx]= min(abs(input_struct.prob_max - obj.empirical_fdr));
            obj.prob_max_ew = HistBin.EDGES(min_idx);
            if (obj.empirical_fdr(min_idx) > input_struct.prob_max) && min_idx > 1
                obj.prob_max_ew = HistBin.EDGES(min_idx - 1);
            end
        end
    end
    
    methods (Access = protected)
        function plotProbVsNetSize(obj, net_atlas, ax)
            import nla.* % required due to matlab package system quirks
            net_size = obj.getNetSizes(net_atlas);
            
            p_val = -log10(obj.prob.v);
            
            % prob vs. net-pair size
            plot(net_size.v, p_val, 'ok');

            % Least-squares regression line
            lsline_coeff = polyfit(net_size.v, p_val, 1);
            lsline_x = linspace(ax.XLim(1), ax.XLim(2), 2);
            lsline_y = polyval(lsline_coeff, lsline_x);
            hold('on');
            plot(lsline_x, lsline_y, 'r');

            xlabel(ax, 'Number of ROI pairs within network pair')
            ylabel(ax, '-log_1_0(Asymptotic P-value)')
            [r, p] = corr(net_size.v, p_val);
            title(ax, 'Non-permuted P-values vs. Net-Pair Size');
            subtitle(ax, sprintf('Check if P-values correlate with net-pair size\n(corr: p = %.2f, r = %.2f)', p, r));
            lims = ylim(ax);
            ylim(ax, [0 lims(2)]);
        end
        
        function plotWithinNetPairProbVsNetSize(obj, net_atlas, ax)
            plotValsVsNetSize(obj, net_atlas, ax, obj.within_np_prob, 'Within Net-Pair P-values vs. Net-Pair Size', '-log_1_0(Within Net-Pair P-value)');
        end
    end
end
