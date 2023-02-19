classdef HyperGeo < nla.net.BaseSigTest
    %HYPERGEO Network level hypergeometric test
    properties (Constant)
        name = "Hypergeometric"
    end
    
    methods
        function obj = HyperGeo()
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseSigTest();
        end
        
        function result = run(obj, input_struct, edge_result, net_atlas, previous_result)
            import nla.* % required due to matlab package system quirks
            %RUN Run the test
            %   edge_result: Result of edge-level statistics
            %   net_atlas: Network atlas
            %   previous_result: Optional parameter which can either be
            %   'false', signifying that this is a non-permuted run, or a
            %   non-permuted HyperGeoResult, indicating that this is a
            %   permuted run, which is dependant on the non-permuted result
            
            num_nets = net_atlas.numNets();
            
            observed_gt_expected = TriMatrix(num_nets, 'logical', TriMatrixDiag.KEEP_DIAGONAL);
            prob = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            
            for row = 1:num_nets
                for col = 1:row
                    net_pair_ROI_sig = edge_result.prob_sig.get(net_atlas.nets(row).indexes, net_atlas.nets(col).indexes);
                    net_ROI_count = numel(net_pair_ROI_sig);
                    observed_sig = sum(net_pair_ROI_sig);
                    expected_sig = edge_result.avg_prob_sig * net_ROI_count;
                    observed_gt_expected.set(row, col, observed_sig > expected_sig);
                    prob.set(row, col, hygecdf(observed_sig, numel(edge_result.prob_sig.v), sum(edge_result.prob_sig.v), net_ROI_count, 'upper'));
                end
            end
            
            prob.v(~observed_gt_expected.v) = 1;
            
            % if a previous result is passed in, add on to it
            if previous_result ~= false
                result = previous_result;
                result.perm_rank.v = result.perm_rank.v + uint64(prob.v <= result.prob.v + ACCURACY_MARGIN);
                result.within_np_rank.v = result.within_np_rank.v + uint64(prob.v <= result.prob.v + ACCURACY_MARGIN);
                
                for i = 1:net_atlas.numNetPairs()
                    result.perm_rank_ew.v(i) = result.perm_rank_ew.v(i) + sum(uint64(prob.v <= result.prob.v(i) + ACCURACY_MARGIN));
                end
                
                result.perm_prob_hist = result.perm_prob_hist + uint32(histcounts(prob.v, HistBin.EDGES)');
                result.perm_count = result.perm_count + 1;
            else
                result = net.result.HyperGeo(num_nets);
                result.observed_gt_expected = observed_gt_expected;
                result.prob = prob;
            end
        end
    end
end

