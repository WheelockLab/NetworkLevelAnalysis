classdef CohenD < nla.net.BaseCorrTest
    %COHEND Net-level Cohen's D test
    properties (Constant)
        name = "Cohen's D"
    end
    
    methods (Static)
        function [d, within_np_d] = effectSizes(edge_result, net_atlas)
            num_nets = net_atlas.numNets();
            d = nla.TriMatrix(num_nets, nla.TriMatrixDiag.KEEP_DIAGONAL);
            within_np_d = nla.TriMatrix(num_nets, nla.TriMatrixDiag.KEEP_DIAGONAL);
            
            for row = 1:num_nets
                for col = 1:row
                    coeff_net = edge_result.coeff.get(net_atlas.nets(row).indexes, net_atlas.nets(col).indexes);
                    d_val = abs((mean(coeff_net) - mean(edge_result.coeff.v)) / sqrt(((std(coeff_net) .^ 2) + (std(edge_result.coeff.v) .^ 2)) / 2));
                    d.set(row, col, d_val);
                    within_np_d_val = nla.net.ssCohenD(coeff_net, edge_result.coeff.v);
                    within_np_d.set(row, col, within_np_d_val);
                end
            end
        end
    end
    
    methods
        function obj = CohenD()
            obj@nla.net.BaseCorrTest();
        end
        
        function result = run(obj, input_struct, edge_result, net_atlas, previous_result)
            num_nets = net_atlas.numNets();
            
            [d, within_np_d] = nla.net.test.CohenD.effectSizes(edge_result, net_atlas);
            
            % if a previous result is passed in, add on to it
            if previous_result ~= false
                result = obj.rank(net_atlas, previous_result, input_struct, @ge, previous_result.d, false, d, false,...
                    false, false, false, false);
            else
                result = nla.net.result.CohenD(num_nets);
                result.d = d;
                result.within_np_d = within_np_d;
            end
        end
    end
end

