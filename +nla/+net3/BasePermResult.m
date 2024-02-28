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
        within_np_rank
        within_np_prob
    end
    
    methods
        function obj = BasePermResult(size)
            import nla.* % required due to matlab package system quirks
            % permuted stats
            obj.perm_rank = TriMatrix(size, 'uint64', TriMatrixDiag.KEEP_DIAGONAL);
            obj.perm_rank_ew = TriMatrix(size, 'uint64', TriMatrixDiag.KEEP_DIAGONAL);
            obj.perm_prob = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
            obj.perm_prob_ew = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
            
            %% Within Net-Pair (withinNP)
            obj.within_np_rank = TriMatrix(size, 'uint64', TriMatrixDiag.KEEP_DIAGONAL);
            obj.within_np_prob = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
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
                obj.within_np_rank.v = obj.within_np_rank.v + results{j}.within_np_rank.v;
            end
            
            % Results based on summations
            obj.perm_prob.v = double(1 + obj.perm_rank.v) ./ double(1 + obj.perm_count);
            obj.perm_prob_ew.v = double(1 + obj.perm_rank_ew.v) ./ double(1 + (obj.perm_count * num_pairs));
            obj.within_np_prob.v = double(1 + obj.within_np_rank.v) ./ double(1 + obj.perm_count);
        end
        
        function table_new = genSummaryTable(obj, table_old)
            import nla.* % required due to matlab package system quirks
            table_new = [table_old, table(obj.perm_prob_ew.v, 'VariableNames', [obj.name + " P-value"])];
        end
    end
    
    methods (Static)
        function inputs = tweakableInputs()
            % Inputs that can be tweaked post-run (ie: are simple
            % thresholds etc. for summary statistics, or generally can be
            % modified without requiring re-permutation)
            import nla.* % required due to matlab package system quirks
            inputs = {inputField.Integer('behavior_count', 'Test count:', 1, 1, Inf), inputField.Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1)};
        end
    end
    
    methods (Access = protected)
        function [cm, plot_mat, plot_max, name_label, sig_increasing, plot_sig] = genProbPlotParams(obj, input_struct, net_atlas, plot_prob, plot_sig_filter, name_formatted, plot_name, fdr_correction, method)
            import nla.* % required due to matlab package system quirks

            % if no filter is provided on which net-pairs should be
            % significant, create a mask of all true values
            if ~exist('plot_sig_filter', 'var') || islogical(plot_sig_filter)
                plot_sig_filter = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                plot_sig_filter.v = true(numel(plot_sig_filter.v), 1);
            end
            
            if input_struct.prob_plot_method == gfx.ProbPlotMethod.NEG_LOG_10
                plot_name = sprintf('%s (-log_1_0(P))', plot_name);
            end
            
            p_max = fdr_correction.correct(net_atlas, input_struct, plot_prob);
            p_breakdown_label = fdr_correction.createLabel(net_atlas, input_struct, plot_prob);
            
            name_label = sprintf('%s %s\nP < %.2g (%s)', name_formatted, plot_name, p_max, p_breakdown_label);
            
            % which networks to mark as significant
            plot_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
            plot_sig.v = (plot_prob.v < p_max) & plot_sig_filter.v;
            
            discrete_colors_count = 1000;

            % scale values very slightly for display so numbers just below
            % the threshold don't show up white but marked significant
            plot_prob_sc = TriMatrix(net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
            plot_prob_sc.v = plot_prob.v .* (discrete_colors_count / (discrete_colors_count + 1));

            if input_struct.prob_plot_method == gfx.ProbPlotMethod.LOG
                min_log = log10(min(nonzeros(plot_prob.v)));
                if min_log < -40
                    min_log = -40;
                end
                % relevant for BH/BY correction
                if p_max == 0
                    cm = [1 1 1];
                else
                    cm_base = parula(discrete_colors_count);
                    cm = flip(cm_base(ceil(logspace(min_log, 0, discrete_colors_count) .* discrete_colors_count), :));
                    cm = [cm; [1 1 1]];
                end
                plot_mat = plot_prob_sc;
                plot_max = p_max;
                sig_increasing = false;
            elseif input_struct.prob_plot_method == gfx.ProbPlotMethod.NEG_LOG_10
                cm = parula(discrete_colors_count);
                plot_mat = nla.TriMatrix(net_atlas.numNets(), 'double', nla.TriMatrixDiag.KEEP_DIAGONAL);
                plot_mat.v = -1 * log10(plot_prob.v);
                if method == nla.Method.FULL_CONN || method == nla.Method.WITHIN_NET_PAIR
                    plot_max = 2;
                else
                    plot_max = 40;
                end
                sig_increasing = true;
            else
                % relevant for BH/BY correction
                if p_max == 0
                    cm = [1 1 1];
                else
                    cm = flip(parula(discrete_colors_count));
                    cm = [cm; [1 1 1]];
                end
                plot_mat = plot_prob_sc;
                plot_max = p_max;
                sig_increasing = false;
            end
        end
        
        function [w, h] = plotProb(obj, edge_input_struct, input_struct, net_atlas, fig, x, y, plot_prob, plot_sig_filter, plot_name, fdr_correction, method, edge_result)
            import nla.* % required due to matlab package system quirks
            
            %% callback function
            function brainFigsButtonClickedCallback(net1, net2)
                f = waitbar(0.05, sprintf('Generating %s - %s net-pair brain plot', net_atlas.nets(net1).name, net_atlas.nets(net2).name));
                gfx.drawBrainVis(edge_input_struct, input_struct, net_atlas, gfx.MeshType.STD, 0.25, 3, true, edge_result, net1, net2, isa(obj, 'nla.net.BaseSigResult'));
                waitbar(0.95);
                close(f)
            end
            
            %% trimatrix plot
            [cm, plot_mat, plot_max, name_label, ~, plot_sig] = genProbPlotParams(obj, input_struct, net_atlas, plot_prob, plot_sig_filter, obj.name_formatted, plot_name, fdr_correction, method);
            [w, h] = gfx.drawMatrixOrg(fig, x, y, name_label, plot_mat, 0, plot_max, net_atlas.nets, gfx.FigSize.SMALL, gfx.FigMargins.WHITESPACE, false, true, cm, plot_sig, false, @brainFigsButtonClickedCallback);
        end
        
        function genChordPlotFig(obj, edge_input_struct, input_struct, net_atlas, edge_result, plot_sig, plot_mat, plot_max, cm, name_label, sig_increasing, chord_type)
            import nla.* % required due to matlab package system quirks
            
            ax_width = 750;
            trimat_width = 500;
            bottom_text_height = 250;
            
            if sig_increasing && plot_max < 1
                coeff_bounds = [plot_max, 1];
            else
                coeff_bounds = [0, plot_max];
            end
            
            %% Chord plot
            if chord_type == nla.PlotType.CHORD
                fig = gfx.createFigure(ax_width + trimat_width, ax_width);
                
                ax = axes(fig, 'Units', 'pixels', 'Position', [trimat_width, 0, ax_width, ax_width]);
                gfx.hideAxes(ax);
                
                if sig_increasing
                    sig_type = gfx.SigType.INCREASING;
                    insignificant = coeff_bounds(1);
                else
                    sig_type = gfx.SigType.DECREASING;
                    insignificant = coeff_bounds(2);
                end
                
                % threshold out insignificant network pairs for all chord
                % plots
                plot_mat2 = copy(plot_mat);
                plot_mat2.v(~plot_sig.v) = insignificant;
                
                gfx.drawChord(ax, 500, net_atlas, plot_mat2, cm, sig_type, chord_type, coeff_bounds(1), coeff_bounds(2));
            else
                if isfield(input_struct, 'edge_chord_plot_method')
                    edge_plot_type = input_struct.edge_chord_plot_method;
                else
                    edge_plot_type = gfx.EdgeChordPlotMethod.PROB;
                end
                
                split_plot = (edge_plot_type == gfx.EdgeChordPlotMethod.COEFF_SPLIT || edge_plot_type == gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT);
                
                range_limit = std(edge_result.coeff.v) * 5;
                coeff_min = -range_limit;
                coeff_max = range_limit;
                
                vals_clipped = TriMatrix(net_atlas.numROIs(), TriMatrixDiag.REMOVE_DIAGONAL);
                if edge_plot_type == gfx.EdgeChordPlotMethod.COEFF
                    cm_edge = turbo(1000);
                    vals_clipped.v = edge_result.coeff.v;
                    sig_type = gfx.SigType.ABS_INCREASING;
                    insig = 0;
                    title_main = sprintf("Edge-level correlation (P < %g) (Within Significant Net-Pair)", edge_result.prob_max);
                elseif edge_plot_type == gfx.EdgeChordPlotMethod.COEFF_SPLIT
                    cm_edge = turbo(1000);
                    vals_clipped_pos = TriMatrix(net_atlas.numROIs(), TriMatrixDiag.REMOVE_DIAGONAL);
                    vals_clipped_pos.v = edge_result.coeff.v;
                    vals_clipped_pos.v(edge_result.coeff.v < 0) = 0;
                    vals_clipped.v = edge_result.coeff.v;
                    vals_clipped.v(edge_result.coeff.v > 0) = 0;
                    sig_type = gfx.SigType.ABS_INCREASING;
                    insig = 0;
                    title_main = sprintf("Negative edge-level correlation (P < %g) (Within Significant Net-Pair)", edge_result.prob_max);
                    title_pos_main = sprintf("Positive edge-level correlation (P < %g) (Within Significant Net-Pair)", edge_result.prob_max);
                elseif edge_plot_type == gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT
                    cm_edge = turbo(1000);
                    vals_clipped_pos = TriMatrix(net_atlas.numROIs(), TriMatrixDiag.REMOVE_DIAGONAL);
                    vals_clipped_pos.v = edge_result.coeff.v;
                    vals_clipped_pos.v(edge_result.coeff.v < 0) = 0;
                    vals_clipped.v = edge_result.coeff.v;
                    vals_clipped.v(edge_result.coeff.v > 0) = 0;
                    sig_type = gfx.SigType.ABS_INCREASING;
                    coeff_min = edge_result.coeff_range(1);
                    coeff_max = edge_result.coeff_range(2);
                    insig = 0;
                    title_main = sprintf("Negative edge-level correlation (P < %g) (Within Significant Net-Pair)", edge_result.prob_max);
                    title_pos_main = sprintf("Positive edge-level correlation (P < %g) (Within Significant Net-Pair)", edge_result.prob_max);
                elseif edge_plot_type == gfx.EdgeChordPlotMethod.COEFF_BASE
                    cm_edge = turbo(1000);
                    vals_clipped.v = edge_result.coeff.v;
                    sig_type = gfx.SigType.ABS_INCREASING;
                    coeff_min = edge_result.coeff_range(1);
                    coeff_max = edge_result.coeff_range(2);
                    insig = 0;
                    title_main = sprintf("Edge-level correlation coefficient (P < %g) (Within Significant Net-Pair)", edge_result.prob_max);
                else
                    cm_edge_base = parula(1000);
                    cm_edge = flip(cm_edge_base(ceil(logspace(-3, 0, 1000) .* 1000), :));
                    vals_clipped.v = edge_result.prob.v;
                    sig_type = gfx.SigType.DECREASING;
                    coeff_min = 0;
                    coeff_max = edge_result.prob_max;
                    insig = 1;
                    title_main = sprintf("Edge-level P-values (P < %g) (Within Significant Net-Pair)", edge_result.prob_max);
                end
                
                % threshold out insignificant networks
                for y = 1:net_atlas.numNets()
                    for x = 1:y
                        if ~plot_sig.get(y, x)
                            vals_clipped.set(net_atlas.nets(y).indexes, net_atlas.nets(x).indexes, insig);
                            if split_plot
                                vals_clipped_pos.set(net_atlas.nets(y).indexes, net_atlas.nets(x).indexes, insig);
                            end
                        end
                    end
                end
                
                if split_plot
                    fig = gfx.createFigure((ax_width * 2) + trimat_width - 100, ax_width);
                else
                    fig = gfx.createFigure(ax_width + trimat_width, ax_width);
                end
                
                ax = axes(fig, 'Units', 'pixels', 'Position', [trimat_width, 0, ax_width - 50, ax_width - 50]);
                gfx.hideAxes(ax);
                ax.Visible = true; % to show title
                
                if split_plot
                    % plot positive chord
                    positive_chord_plotter = nla.gfx.chord.ChordPlot(net_atlas, ax, 450, vals_clipped_pos,...
                        'direction', sig_type, 'color_map', cm_edge, 'chord_type', chord_type, 'upper_limit', coeff_max, 'lower_limit', coeff_min);
                    positive_chord_plotter.drawChords();
                    % gfx.drawChord(ax, 450, net_atlas, vals_clipped_pos, cm_edge, sig_type, chord_type, coeff_min, coeff_max);
                    gfx.setTitle(ax, title_pos_main);
                    
                    % make new axes for other chord plot, shifted right
                    ax = axes(fig, 'Units', 'pixels', 'Position', [trimat_width + ax_width - 100, 0, ax_width - 50, ax_width - 50]);
                    gfx.hideAxes(ax);
                    ax.Visible = true; % to show title
                end

                chord_plotter = nla.gfx.chord.ChordPlot(net_atlas, ax, 450, vals_clipped, 'direction', sig_type, 'color_map', cm_edge, 'upper_limit', coeff_max, 'lower_limit', coeff_min, 'chord_type', chord_type);
                chord_plotter.drawChords();
                % gfx.drawChord(ax, 450, net_atlas, vals_clipped, cm_edge, sig_type, chord_type, coeff_min, coeff_max);
                gfx.setTitle(ax, title_main);
                
                colormap(ax, cm_edge);
                cb = colorbar(ax);
                cb.Units = 'pixels';
                cb.Location = 'east';
                cb.Position = [cb.Position(1) + 25, cb.Position(2) + 100, cb.Position(3), cb.Position(4) - 200];
                
                num_ticks = 10;
                ticks = [0:num_ticks];
                cb.Ticks = double(ticks) ./ num_ticks;

                % tick labels
                labels = {};
                for i = ticks
                    labels{i + 1} = sprintf("%.2g", coeff_min + (i * ((coeff_max - coeff_min) / num_ticks)));
                end
                cb.TickLabels = labels;
            end

            fig.Renderer = 'painters';
            
            %% Trimatrix plot
            function brainFigsButtonClickedCallback(net1, net2)
                f = waitbar(0.05, sprintf('Generating %s - %s net-pair brain plot', net_atlas.nets(net1).name, net_atlas.nets(net2).name));
                gfx.drawBrainVis(edge_input_struct, input_struct, net_atlas, gfx.MeshType.STD, 0.25, 3, true, edge_result, net1, net2, isa(obj, 'nla.net.BaseSigResult'));
                waitbar(0.95);
                close(f)
            end
            gfx.drawMatrixOrg(fig, 25, bottom_text_height, name_label, plot_mat, coeff_bounds(1), coeff_bounds(2), net_atlas.nets, gfx.FigSize.SMALL, gfx.FigMargins.WHITESPACE, false, true, cm, plot_sig, false, @brainFigsButtonClickedCallback);
            
            %% Plot names
            text_ax = axes(fig, 'Units', 'pixels', 'Position', [55, bottom_text_height + 15, 450, 75]);
            gfx.hideAxes(text_ax);
            info_text = "Click any net-pair in the above plot to view its edge-level correlations.";
            if chord_type == nla.PlotType.CHORD_EDGE
                info_text = sprintf("%s\n\nChord plot:\nEach ROI is marked by a dot next to its corresponding network.\nROIs are placed in increasing order counter-clockwise, the first ROI in\na network being the most clockwise, the last being the most counter-\nclockwise.", info_text);
            end
            text(text_ax, 0, 0, info_text, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
        end
        
        function plotChord(obj, edge_input_struct, input_struct, net_atlas, plot_prob, plot_sig_filter, plot_name, fdr_correction, method, edge_result, chord_type)
            import nla.* % required due to matlab package system quirks
            [cm, plot_mat, plot_max, name_label, sig_increasing, plot_sig] = genProbPlotParams(obj, input_struct, net_atlas, plot_prob, plot_sig_filter, obj.name_formatted, plot_name, fdr_correction, method);
            genChordPlotFig(obj, edge_input_struct, input_struct, net_atlas, edge_result, plot_sig, plot_mat, plot_max, cm, name_label, sig_increasing, chord_type);
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
        
        function plotValsVsNetSize(obj, net_atlas, ax, prob, title_label, y_label, val_name)
            import nla.* % required due to matlab package system quirks
            
            if ~exist('val_name', 'var'), val_name = 'P-values'; end
            
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
            gfx.setTitle(ax, title_label);
            gfx.setTitle(ax, sprintf('Check if %s correlate with net-pair size\n(corr: p = %.2f, r = %.2f)', val_name, p, r), true);
            lims = ylim(ax);
            ylim(ax, [0 lims(2)]);
        end
    end
end
