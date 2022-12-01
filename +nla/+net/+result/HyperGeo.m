classdef HyperGeo < nla.net.BaseSigResult
    %HYPERGEO The output result of a Hyper-geometric test
    
    properties (Constant)
        name = "Hypergeometric"
        name_formatted = "Hypergeometric"
    end
    
    methods
        function obj = HyperGeo(size)
            import nla.* % required due to matlab package system quirks
            % Superclass constructor
            obj@nla.net.BaseSigResult(size);
        end
        
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            import nla.* % required due to matlab package system quirks
            merge@nla.net.BaseResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
            
            %% Within Net-Pair statistics (withinNP)
            num_nets = net_atlas.numNets();
            for row = 1:num_nets
                for col = 1:row
                    % get permuted and nonpermuted edge-level probabilities
                    i_row = net_atlas.nets(row).indexes;
                    i_col = net_atlas.nets(col).indexes;
                    prob_net = edge_result_nonperm.prob_sig.get(i_row, i_col);
                    prob_net_perm = edge_result.prob.get(i_row, i_col);
                    
                    net_ROI_count = numel(prob_net);
                    observed = sum(prob_net);
                    expected = sum(prob_net_perm, 'all') ./ double(net_ROI_count * obj.perm_count);
                    obj.within_np_prob.set(row, col, hygecdf(observed, double(net_ROI_count * obj.perm_count), sum(prob_net_perm, 'all'), net_ROI_count, 'upper') .^ (observed > expected));
                end
            end
        end
        
        function table_new = genSummaryTable(obj, table_old)
            import nla.* % required due to matlab package system quirks
            table_new = genSummaryTable@nla.net.BasePermResult(obj, table_old);
        end
    end
end
