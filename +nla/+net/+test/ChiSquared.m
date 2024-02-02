classdef ChiSquared < nla.net.BaseSigTest
    %CHISQUARED Network level Chi squared test
    properties (Constant)
        name = "Chi-squared"
    end
    
    methods
        function obj = ChiSquared()
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
            %   non-permuted ChiSquaredResult, indicating that this is a
            %   permuted run, which is dependant on the non-permuted result
            
            num_nets = net_atlas.numNets();
            
            chi2 = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            observed_gt_expected = TriMatrix(num_nets, 'logical', TriMatrixDiag.KEEP_DIAGONAL);
            
            for row = 1:num_nets
                for col = 1:row
                    net_pair_ROI_sig = edge_result.prob_sig.get(net_atlas.nets(row).indexes, net_atlas.nets(col).indexes);
                    net_ROI_count = numel(net_pair_ROI_sig);
                    observed_sig = sum(net_pair_ROI_sig);
                    expected_sig = edge_result.avg_prob_sig * net_ROI_count;
                    chi2_val = ((observed_sig - expected_sig) .^ 2) .* (expected_sig .^ -1);
                    chi2.set(row, col, chi2_val);
                    observed_gt_expected.set(row, col, observed_sig > expected_sig);
                end
            end
            
            % We expect a certain level of significant ROI pairs in a
            % network due to random chance. If we observe less than
            % that we can be confident that the network in question
            % definitely isn't significant, and assign it a chi stat of
            % 0, which translates to a pval of 1.
            chi2.v(~observed_gt_expected.v) = 0;
            chi2.v(~isfinite(chi2.v)) = 0;
            
            % Calculate probability from chi2 value
            prob = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            prob.v = chi2cdf(chi2.v, 1, 'upper');
            
            % If a previous non-permuted result is passed in, add on to it
            result = net.result.ChiSquared(num_nets);
            result.chi2 = chi2;
            result.observed_gt_expected = observed_gt_expected;
            result.prob = prob;
            
        end
    end
end

