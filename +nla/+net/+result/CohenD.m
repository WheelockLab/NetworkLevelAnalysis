classdef CohenD < nla.net.BasePermResult
    properties (Constant)
        name = "Cohen's D"
        name_formatted = "Cohen's D"
        has_within_net_pair = true
        has_full_conn = true
        has_nonpermuted = false
    end
    
    properties
        d
        within_np_d
    end
    
    methods
        function obj = CohenD(size)
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BasePermResult(size);
            
            % non-permuted stats
            obj.d = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
            
            %% Within Net-Pair statistics (withinNP)
            obj.within_np_d = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            import nla.* % required due to matlab package system quirks
            % Summations
            merge@nla.net.BasePermResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
        end
        
        function output(obj, edge_input_struct, input_struct, net_atlas, edge_result, flags)
            import nla.* % required due to matlab package system quirks

            %% callback function
            function brainFigsButtonClickedCallback(net1, net2)
                f = waitbar(0.05, sprintf('Generating %s - %s net-pair brain plot', net_atlas.nets(net1).name, net_atlas.nets(net2).name));
                gfx.drawBrainVis(edge_input_struct, input_struct, net_atlas, gfx.MeshType.STD, 0.25, 3, true, edge_result, net1, net2, isa(obj, 'nla.net.BaseSigResult'));
                waitbar(0.95);
                close(f)
            end
            
            if obj.perm_count > 0
                if isfield(flags, 'show_full_conn') && flags.show_full_conn
                    d_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    d_sig.v = obj.d.v >= input_struct.d_max;
                    name_label = sprintf("Observed %s Full Connectome Significance\nD > %g", obj.name_formatted, input_struct.d_max);
                    
                    if flags.plot_type == nla.PlotType.FIGURE
                        %% Permuted probability (fullConn)
                        fig = gfx.createFigure(500, 1000);

                        %% Check that network-pair size is not a confound
                        %obj.plotPermProbVsNetSize(net_atlas, subplot(2,1,2));
                        obj.plotValsVsNetSize(net_atlas, subplot(2,1,2), obj.d, "Full Connectome Observed Cohen's D vs. Net-Pair Size", "Cohen's D", "Cohen's D effect sizes");

                        %% Matrix plot
                        matrix_plot = gfx.plots.MatrixPlot(fig, name_label, obj.d, net_atlas.nets, gfx.FigSize.SMALL,...
                        'network_clicked_callback', @brainFigsButtonClickedCallback, 'marked_networks', d_sig,...
                        'draw_legend', false, 'color_map', [1,1,1;parula(256)], 'lower_limit', input_struct.d_max,...
                        'upper_limit', 1, 'x_position', 0, 'y_position', 525);
                        matrix_plot.displayImage();
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.genChordPlotFig(edge_input_struct, input_struct, net_atlas, edge_result, d_sig, obj.d, input_struct.d_max, [1,1,1;parula(256)], name_label, true, flags.plot_type);
                    end
                end
                
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    within_np_d_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    within_np_d_sig.v = obj.within_np_d.v >= input_struct.d_max;
                    name_label = sprintf("%s Within Net-Pair Significance\nD > %g", obj.name_formatted, input_struct.d_max);
                    
                    if flags.plot_type == nla.PlotType.FIGURE
                        %% Within Net-Pair statistics (withinNP)
                        fig = gfx.createFigure();
                        matrix_plot2 = gfx.plots.MatrixPlot(fig, name_label, obj.within_np_d, net_atlas.nets, gfx.FigSize.SMALL,...
                            'network_clicked_callback', @brainFigsButtonClickedCallback, 'marked_networks', within_np_d_sig,...
                            'draw_legend', false, 'color_map', [1,1,1;parula(256)], 'upper_limit', input_struct.d_max, 'lower_limit', 1);
                        fig.Position(3) = matrix_plot2.image_dimensions("image_width");
                        fig.Position(4) = matrix_plot2.image_dimensions("image_height");
                        matrix_plot2.displayImage();
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.genChordPlotFig(edge_input_struct, input_struct, net_atlas, edge_result, within_np_d_sig, obj.within_np_d, input_struct.d_max, [1,1,1;parula(256)], name_label, true, flags.plot_type);
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
                    sig_count_mat.v = sig_count_mat.v + (obj.d.v >= input_struct.d_max);
                    names = [names sprintf("Full Connectome Observed %s (D > %g)", obj.name, input_struct.d_max)];
                end
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    num_tests = num_tests + 1;
                    sig_count_mat.v = sig_count_mat.v + (obj.within_np_d.v >= input_struct.d_max);
                    names = [names sprintf("Within Net-Pair %s (D > %g)", obj.name, input_struct.d_max)];
                end
            end
        end
        
        function table_new = genSummaryTable(obj, table_old)
            import nla.* % required due to matlab package system quirks
            table_new = [genSummaryTable@nla.net.BasePermResult(obj, table_old), table(obj.d.v, 'VariableNames', [obj.name])];
        end
    end
end