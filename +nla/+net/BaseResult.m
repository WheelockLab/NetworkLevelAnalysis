classdef BaseResult < nla.net.BasePermResult
    %BASERESULT Base class of results of net-level analysis
    properties (Constant)
        has_full_conn = true
        has_nonpermuted = true
    end
    
    properties
        prob
        ss_prob
        perm_prob_hist
    end
    
    methods
        function obj = BaseResult(size)
            obj@nla.net.BasePermResult(size);
            
            % non-permuted stats
            obj.prob = nla.TriMatrix(size, nla.TriMatrixDiag.KEEP_DIAGONAL);

            % permuted stats
            obj.perm_prob_hist = zeros(nla.HistBin.SIZE, 'uint32');
        end
        
        function output(obj, edge_input_struct, input_struct, net_atlas, edge_result, flags)
            if obj.perm_count == 0
                if isfield(flags, 'show_nonpermuted') && flags.show_nonpermuted
                    if flags.plot_type == nla.PlotType.FIGURE
                        %% Non-permuted
                        fig = nla.gfx.createFigure(500, 900);

                        %% Check that network-pair size is not a confound
                        obj.plotProbVsNetSize(net_atlas, subplot(2,1,2));
                        
                        %% Matrix with significant networks marked
                        obj.plotProb(edge_input_struct, input_struct, net_atlas, fig, 0, 425, obj.prob, false,...
                            sprintf('Non-permuted Method\nNon-permuted Significance'), input_struct.fdr_correction,...
                            nla.Method.NONPERMUTED, edge_result);
                      
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.plotChord(edge_input_struct, input_struct, net_atlas, obj.prob, false,...
                            sprintf('Non-permuted Method\nNon-permuted Significance'), input_struct.fdr_correction,...
                            nla.Method.NONPERMUTED, edge_result, flags.plot_type);
                    end
                end
            end
        end
        
        function [num_tests, sig_count_mat, names] = getSigMat(obj, input_struct, net_atlas, flags)
            num_tests = 0;
            sig_count_mat = nla.TriMatrix(net_atlas.numNets(), 'double', nla.TriMatrixDiag.KEEP_DIAGONAL);
            names = [];
            
            if obj.perm_count == 0
                if isfield(flags, 'show_nonpermuted') && flags.show_nonpermuted
                    [sig, name] = obj.singleSigMat(net_atlas, input_struct, obj.prob, input_struct.fdr_correction,...
                        "Non-Permuted");
                    [num_tests, sig_count_mat, names] = obj.appendSigMat(num_tests, sig_count_mat, names, sig, name);
                end
            else
                if isfield(flags, 'show_full_conn') && flags.show_full_conn
                    [sig, name] = obj.singleSigMat(net_atlas, input_struct, obj.perm_prob_ew, nla.net.mcc.None,...
                        "Full Connectome");
                    [num_tests, sig_count_mat, names] = obj.appendSigMat(num_tests, sig_count_mat, names, sig, name);
                end
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    [sig, name] = obj.singleSigMat(net_atlas, input_struct, obj.within_np_prob, input_struct.fdr_correction,...
                        "Within Net-Pair");
                    [num_tests, sig_count_mat, names] = obj.appendSigMat(num_tests, sig_count_mat, names, sig, name);
                end
            end
        end
        
        % merged is a function which merges 2 results from the same test
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            merge@nla.net.BasePermResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
            
            % Histogram
            for j = 1:numel(results)
                obj.perm_prob_hist = obj.perm_prob_hist + results{j}.perm_prob_hist;
            end
        end
    end
    
    methods (Access = protected)
        function [num_tests, sig_count_mat, names] = appendSigMat(obj, num_tests, sig_count_mat, names, sig, name)
            num_tests = num_tests + 1;
            sig_count_mat.v = sig_count_mat.v + sig.v;
            names = [names name];
        end
        
        function [sig, name] = singleSigMat(obj, net_atlas, input_struct, prob, mcc_method, title_prepend)
            p_max = mcc_method.correct(net_atlas, input_struct, prob);
            p_breakdown_label = mcc_method.createLabel(net_atlas, input_struct, prob);
            
            sig = nla.TriMatrix(net_atlas.numNets(), 'double', nla.TriMatrixDiag.KEEP_DIAGONAL);
            sig.v = (prob.v < p_max);
            
            name = sprintf("%s %s P < %.2g (%s)", title_prepend, obj.name, p_max, p_breakdown_label);
        end
        
        function plotProbHist(obj, ax, prob_max)
            import nla.HistBin

            empirical_fdr = zeros(HistBin.SIZE);
            empirical_fdr = cumsum(double(obj.perm_prob_hist) ./ sum(obj.perm_prob_hist));
            [~, min_idx]= min(abs(prob_max - empirical_fdr));
            prob_max_ew = HistBin.EDGES(min_idx);
            if (empirical_fdr(min_idx) > prob_max) && min_idx > 1
                prob_max_ew = HistBin.EDGES(min_idx - 1);
            end
            
            loglog(ax, HistBin.EDGES(2:end), empirical_fdr, 'k');
            hold('on');
            loglog(ax, obj.prob.v, obj.perm_prob_ew.v, 'ok');
            axis([min(obj.prob.v), 1, min(obj.perm_prob_ew.v), 1])            
            loglog(ax, ax.XLim, [prob_max, prob_max], 'b');
            loglog(ax, [prob_max_ew, prob_max_ew], ax.YLim, 'r');

            name_label = sprintf("%s P-values", obj.name_formatted);
            nla.gfx.setTitle(ax, name_label);
            xlabel(ax, 'Asymptotic');
            ylabel(ax, 'Permutation-based P-value');
        end
        
        function plotProbVsNetSize(obj, net_atlas, ax)
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
            nla.gfx.setTitle(ax, 'Non-permuted P-values vs. Net-Pair Size');
            nla.gfx.setTitle(ax, sprintf('Check if P-values correlate with net-pair size\n(corr: p = %.2f, r = %.2f)',...
                p, r), true);
            lims = ylim(ax);
            ylim(ax, [0 lims(2)]);
        end
        
        function plotWithinNetPairProbVsNetSize(obj, net_atlas, ax)
            plotValsVsNetSize(obj, net_atlas, ax, obj.within_np_prob, 'Within Net-Pair P-values vs. Net-Pair Size',...
                '-log_1_0(Within Net-Pair P-value)');
        end
    end
end
