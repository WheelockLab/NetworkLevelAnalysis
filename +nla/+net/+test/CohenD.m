classdef CohenD < nla.net.BaseCorrTest
    %COHEND Net-level Cohen's D test
    properties (Constant)
        name = "Cohen's D"
    end
    
    methods
        function obj = CohenD()
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseCorrTest();
        end
        
        function result = run(obj, input_struct, edge_result, net_atlas, previous_result)
            import nla.* % required due to matlab package system quirks
            num_nets = net_atlas.numNets();
            d = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            within_np_d = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            for row = 1:num_nets
                for col = 1:row
                    coeff_net = edge_result.coeff.get(net_atlas.nets(row).indexes, net_atlas.nets(col).indexes);
                    d_val = abs((mean(coeff_net) - mean(edge_result.coeff.v)) / sqrt(((std(coeff_net) .^ 2) + (std(edge_result.coeff.v) .^ 2)) / 2));
                    d.set(row, col, d_val);
                    within_np_d_val = net.ssCohensD(coeff_net, edge_result.coeff.v);
                    within_np_d.set(row, col, within_np_d_val);
                end
            end
            
            % if a previous result is passed in, add on to it
            if previous_result ~= false
                result = previous_result;
                
                result.perm_rank.v = result.perm_rank.v + uint64(d.v >= result.d.v - ACCURACY_MARGIN);
                
                for i = 1:net_atlas.numNetPairs()
                    result.perm_rank_ew.v(i) = result.perm_rank_ew.v(i) + sum(uint64(d.v >= result.d.v(i) - ACCURACY_MARGIN));
                end
                result.perm_count = result.perm_count + 1;
            else
                result = net.result.CohenD(num_nets);
                result.d = d;
                result.within_np_d = within_np_d;
            end
        end
    end
end

