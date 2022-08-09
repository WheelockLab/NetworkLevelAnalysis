classdef BasePermResult < nla.TestResult
    %BASEPERMRESULT Permuted net-level result
    
    properties (Constant, Abstract)
        name
        name_formatted
    end
    
    properties
        perm_rank
        perm_rank_ew
        perm_prob
        perm_prob_ew
        perm_count = uint32(0)
    end
    
    methods
        function obj = BasePermResult(size)
            import nla.* % required due to matlab package system quirks
            % permuted stats
            obj.perm_rank = TriMatrix(size, 'uint64', TriMatrixDiag.KEEP_DIAGONAL);
            obj.perm_rank_ew = TriMatrix(size, 'uint64', TriMatrixDiag.KEEP_DIAGONAL);

            obj.perm_prob = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
            obj.perm_prob_ew = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        % merged is a function which merges 2 results from the same test
        function merge(obj, ~, ~, ~, ~, results)
            import nla.* % required due to matlab package system quirks
            % Summations
            num_pairs = numel(obj.perm_rank.v);
            for j = 1:numel(results)
                obj.perm_count = obj.perm_count + results{j}.perm_count;
                obj.perm_rank.v = obj.perm_rank.v + results{j}.perm_rank.v;
                obj.perm_rank_ew.v = obj.perm_rank_ew.v + results{j}.perm_rank_ew.v;
            end
            
            % Results based on summations
            obj.perm_prob.v = double(1 + obj.perm_rank.v) ./ double(1 + obj.perm_count);
            obj.perm_prob_ew.v = double(1 + obj.perm_rank_ew.v) ./ double(1 + (obj.perm_count * num_pairs));
        end
    end
    
    methods (Access = protected)
        function [w, h] = plotProb(obj, input_struct, net_atlas, fig, x, y, plot_prob, plot_sig, plot_name, divide_by_netpairs)
            import nla.* % required due to matlab package system quirks
            
            if ~exist('divide_by_netpairs','var'), divide_by_netpairs = false; end
            n_net_pairs = net_atlas.numNetPairs();
            if divide_by_netpairs
                p_max = input_struct.prob_max / n_net_pairs;
            else
                p_max = input_struct.prob_max;
            end
            
            if divide_by_netpairs
                name_label = sprintf("%s %s\nP < %.2g (%g/%d tests/%d net-pairs)", obj.name_formatted, plot_name, p_max, p_max * input_struct.behavior_count * n_net_pairs, input_struct.behavior_count, n_net_pairs);
            else
                name_label = sprintf("%s %s\nP < %.2g (%g/%d tests)", obj.name_formatted, plot_name, p_max, p_max * input_struct.behavior_count, input_struct.behavior_count);
            end
            
            if input_struct.log_plot_prob
                cm_base = parula(1000);
                cm = flip(cm_base(ceil(logspace(-3, 0, 256) .* 1000), :));
                [w, h] = gfx.drawMatrixOrg(fig, x, y, name_label, plot_prob, 0, 1, net_atlas.nets, gfx.FigSize.SMALL, gfx.FigMargins.WHITESPACE, false, true, cm, plot_sig);
            else
                discrete_colors_count = 1000;
                cm = flip(parula(discrete_colors_count));
                cm = [cm; [1 1 1]];
                
                % scale values very slightly for display so numbers just below
                % the threshold don't show up white but marked significant
                plot_prob_sc = TriMatrix(net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
                plot_prob_sc.v = plot_prob.v .* (discrete_colors_count / (discrete_colors_count + 1));
                
                [w, h] = gfx.drawMatrixOrg(fig, x, y, name_label, plot_prob_sc, 0, p_max, net_atlas.nets, gfx.FigSize.SMALL, gfx.FigMargins.WHITESPACE, false, true, cm, plot_sig);
            end
        end
        
        function net_size = getNetSizes(obj, net_atlas)
            import nla.* % required due to matlab package system quirks
            ROI_pairs = TriMatrix(net_atlas.numROIs(), 'logical');
            net_size = TriMatrix(net_atlas.numNets(), TriMatrixDiag.KEEP_DIAGONAL);
            for row = 1:net_atlas.numNets()
                for col = 1:row
                    net_size.set(row, col, numel(ROI_pairs.get(net_atlas.nets(row).indexes, net_atlas.nets(col).indexes)));
                end
            end
        end
        
        function plotPermProbVsNetSize(obj, net_atlas, ax)
            plotValsVsNetSize(obj, net_atlas, ax, obj.perm_prob_ew, 'Permuted P-values vs. Net-Pair Size', '-log_1_0(Permutation-based P-value)');
        end
        
        function plotValsVsNetSize(obj, net_atlas, ax, prob, title_label, y_label)
            import nla.* % required due to matlab package system quirks
            net_size = obj.getNetSizes(net_atlas);
            p_val = -log10(prob.v);
            
            % permuted prob vs. net-pair size
            plot(net_size.v, p_val, 'ok');

            % Least-squares regression line
            lsline_coeff = polyfit(net_size.v, p_val, 1);
            lsline_x = linspace(ax.XLim(1), ax.XLim(2), 2);
            lsline_y = polyval(lsline_coeff, lsline_x);
            hold('on');
            plot(lsline_x, lsline_y, 'r');

            xlabel(ax, 'Number of ROI pairs within network pair')
            ylabel(ax, y_label)
            [r, p] = corr(net_size.v, p_val);
            title(ax, title_label);
            subtitle(ax, sprintf('Check if P-values correlate with net-pair size\n(corr: p = %.2f, r = %.2f)', p, r));
            %ylim(ax, [0 1]);
        end
    end
end
