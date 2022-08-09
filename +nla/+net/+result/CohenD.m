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
            
            %% Within Net-Pair statistics (withinNP)
            num_nets = net_atlas.numNets();
            for row = 1:num_nets
                for col = 1:row
                    % get permuted and nonpermuted edge-level coefficients
                    i_row = net_atlas.nets(row).indexes;
                    i_col = net_atlas.nets(col).indexes;
                    coeff_net = edge_result_nonperm.coeff.get(i_row, i_col);
                    coeff_net_perm = edge_result.coeff_perm.get(i_row, i_col);
                    
                    coeff_net_perm = reshape(coeff_net_perm, [], 1); % TODO testing this line
                    obj.within_np_d.set(row, col, abs((mean(coeff_net) - mean(coeff_net_perm)) / sqrt((std(coeff_net) .^ 2) + (std(coeff_net_perm) .^ 2) / 2)));
                end
            end
        end
        
        function output(obj, input_struct, net_atlas, flags)
            import nla.* % required due to matlab package system quirks
            
            if obj.perm_count > 0
                if isfield(flags, 'show_full_conn') && flags.show_full_conn
                    %% Permuted probability (fullConn)
                    fig = gfx.createFigure(500, 1000);

                    %% Check that network-pair size is not a confound
                    obj.plotPermProbVsNetSize(net_atlas, subplot(2,1,2));

                    %% Matrix plot
                    perm_prob_ew_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    perm_prob_ew_sig.v = obj.perm_prob_ew.v < input_struct.prob_max;
                    obj.plotProb(input_struct, net_atlas, fig, 0, 525, obj.perm_prob_ew, perm_prob_ew_sig, sprintf('Full Connectome Method\nNetwork vs. Connectome Significance'));
                end
                
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    %% Within Net-Pair statistics (withinNP)
                    within_np_d_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    within_np_d_sig.v = obj.within_np_d.v >= input_struct.d_max;

                    name_label = sprintf("%s Within Net-Pair Significance\nD > %g", obj.name_formatted, input_struct.d_max);

                    fig = gfx.createFigure();
                    [fig.Position(3), fig.Position(4)] = gfx.drawMatrixOrg(fig, 0, 0, name_label, obj.within_np_d, 0, 1, net_atlas.nets, gfx.FigSize.SMALL, gfx.FigMargins.WHITESPACE, false, true, parula(256), within_np_d_sig);
                end
            end
        end
    end
end