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
                        gfx.drawMatrixOrg(fig, 0, 525, name_label, obj.d, input_struct.d_max, 1, net_atlas.nets, gfx.FigSize.SMALL, gfx.FigMargins.WHITESPACE, false, true, [1,1,1;parula(256)], d_sig);
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
                        [fig.Position(3), fig.Position(4)] = gfx.drawMatrixOrg(fig, 0, 0, name_label, obj.within_np_d, input_struct.d_max, 1, net_atlas.nets, gfx.FigSize.SMALL, gfx.FigMargins.WHITESPACE, false, true, [1,1,1;parula(256)], within_np_d_sig);
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