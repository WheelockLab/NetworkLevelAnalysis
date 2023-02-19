classdef BaseCorrResult < nla.net.BaseResult
    properties (Constant)
        has_within_net_pair = true
    end
    
    properties
        within_np_d
    end
    
    methods
        function obj = BaseCorrResult(size)
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseResult(size);
            
            %% Within Net-Pair statistics (withinNP)
            obj.within_np_d = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            import nla.* % required due to matlab package system quirks
            merge@nla.net.BaseResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
        end
        
        function output(obj, edge_input_struct, input_struct, net_atlas, edge_result, flags)
            import nla.* % required due to matlab package system quirks
            output@nla.net.BaseResult(obj, edge_input_struct, input_struct, net_atlas, edge_result, flags);
            
            if obj.perm_count > 0
                if isfield(flags, 'show_within_net_pair') && flags.show_within_net_pair
                    within_np_prob_d_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                    within_np_prob_d_sig.v = (obj.within_np_prob.v < input_struct.prob_max) & (obj.within_np_d.v >= input_struct.d_max);
                    name_label = sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair (D > %g)', input_struct.d_max);
                        
                    if flags.plot_type == nla.PlotType.FIGURE
                        %% Within Net-Pair statistics (withinNP)
                        fig = gfx.createFigure(1000, 900);

                        obj.plotWithinNetPairProbVsNetSize(net_atlas, subplot(2,2,3));

                        within_np_prob_sig = TriMatrix(net_atlas.numNets(), 'logical', TriMatrixDiag.KEEP_DIAGONAL);
                        within_np_prob_sig.v = obj.within_np_prob.v < input_struct.prob_max;
                        [w, ~] = obj.plotProb(input_struct, net_atlas, fig, 25, 425, obj.within_np_prob, within_np_prob_sig, sprintf('Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair'), false, nla.Method.WITHIN_NET_PAIR);
                        
                        obj.plotProb(input_struct, net_atlas, fig, w - 50, 425, obj.within_np_prob, within_np_prob_d_sig, name_label, false, nla.Method.WITHIN_NET_PAIR);
                    elseif flags.plot_type == nla.PlotType.CHORD || flags.plot_type == nla.PlotType.CHORD_EDGE
                        obj.plotChord(edge_input_struct, input_struct, net_atlas, obj.within_np_prob, within_np_prob_d_sig, name_label, false, nla.Method.WITHIN_NET_PAIR, edge_result, flags.plot_type);
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
                    sig_count_mat.v = sig_count_mat.v + (obj.within_np_prob.v < input_struct.prob_max) & (obj.within_np_d.v >= input_struct.d_max);
                    names = [names sprintf("Within Net-Pair %s", obj.name)];
                end
            end
        end
    end
end