classdef KolmogorovSmirnov < nla.net.BaseCorrTest
    %KOLMOGOROVSMIRNOV Network level KS test
    properties (Constant)
        name = "Kolmogorov-Smirnov"
    end
    
    methods
        function obj = KolmogorovSmirnov()
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseCorrTest();
        end
        
        function result = run(obj, input_struct, edge_result, net_atlas, previous_result)
            import nla.* % required due to matlab package system quirks

            num_nets = net_atlas.numNets();
            
            prob = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            ks = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            ss_prob = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            ss_ks = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            for row = 1:num_nets
                for col = 1:row
                    coeff_net = edge_result.coeff.get(net_atlas.nets(row).indexes, net_atlas.nets(col).indexes);
                    
                    [~, p_val, ks_val] = kstest2(coeff_net, edge_result.coeff.v);
                    prob.set(row, col, p_val);
                    ks.set(row, col, ks_val);
                    
                    [~, ss_val, ss_ks_val, ~] = kstest(coeff_net);
                    ss_prob.set(row, col, ss_val);
                    ss_ks.set(row, col, ss_ks_val);
                end
            end
            
            % if a previous result is passed in, add on to it
            result = net.result.KolmogorovSmirnov(num_nets);
            result.prob = prob;
            result.ks = ks;
            result.ss_prob = ss_prob;
            result.ss_ks = ss_ks;
            
        end
    end
end

