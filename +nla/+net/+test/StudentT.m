classdef StudentT < nla.net.BaseCorrTest
    %WELCHT Network level Welch T-test
    properties (Constant)
        name = "Student's T"
    end
    
    methods
        function obj = StudentT()
            obj@nla.net.BaseCorrTest();
        end
        
        function result = run(obj, input_struct, edge_result, net_atlas, previous_result)
            import nla.TriMatrix nla.TriMatrixDiag

            num_nets = net_atlas.numNets();
            
            prob = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            t = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            ss_prob = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            ss_t = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            for row = 1:num_nets
                for col = 1:row
                    coeff_net = edge_result.coeff.get(net_atlas.nets(row).indexes, net_atlas.nets(col).indexes);
                    
                    [~, p_val, ~, stats] = ttest2(coeff_net, edge_result.coeff.v);
                    t_val = stats.tstat;
                    prob.set(row, col, p_val);
                    t.set(row, col, t_val);
                    
                    [~, ss_val, ~, ss_stats] = ttest(coeff_net);
                    ss_t_val = ss_stats.tstat;
                    ss_prob.set(row, col, ss_val);
                    ss_t.set(row, col, ss_t_val);
                end
            end
            
            % if a previous result is passed in, add on to it
            if previous_result ~= false
                result = obj.rank(net_atlas, previous_result, input_struct, @helpers.abs_ge, previous_result.t,...
                    previous_result.prob, t, prob, previous_result.ss_t, previous_result.ss_prob, ss_t, ss_prob);
            else
                result = nla.net.result.StudentT(num_nets);
                result.prob = prob;
                result.t = t;
                result.ss_prob = ss_prob;
                result.ss_t = ss_t;
            end
        end
    end
end

