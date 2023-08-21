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
            
            % If a previous non-permuted result is passed in, this is a
            % permutation.
            if previous_result ~= false
                result = previous_result;
                
                % Sum the number of permutations which produce a Chi stat
                % equal to or greater than the non-permuted Chi stat.
                % We will later divide this by the total number of
                % permutations to calculate the p value.
                % Fisher, R.A. (1935) The Design of Experiments, New York: Hafner
                if ~isfield(input_struct, 'ranking_method') || input_struct.ranking_method == RankingMethod.TEST_STATISTIC
                    sig_gt_nonpermuted = chi2.v >= result.chi2.v - ACCURACY_MARGIN;
                else
                    sig_gt_nonpermuted = prob.v <= result.prob.v + ACCURACY_MARGIN;
                end
                result.perm_rank.v = result.perm_rank.v + uint64(sig_gt_nonpermuted);
                result.within_np_rank.v = result.within_np_rank.v + uint64(sig_gt_nonpermuted);
                
                for i = 1:net_atlas.numNetPairs()
                    % Similar to the previous ranking, but experiment-wide
                    % (ranking a network's Chi stat among all permutations
                    % of all networks). Code is subtly different from
                    % previous usage, refactor with care.
                    if ~isfield(input_struct, 'ranking_method') || input_struct.ranking_method == RankingMethod.TEST_STATISTIC
                        sig_gt_nonpermuted = chi2.v >= result.chi2.v(i) - ACCURACY_MARGIN;
                    else
                        sig_gt_nonpermuted = prob.v <= result.prob.v(i) + ACCURACY_MARGIN;
                    end
                    result.perm_rank_ew.v(i) = result.perm_rank_ew.v(i) + sum(uint64(sig_gt_nonpermuted));
                end
                
                result.perm_prob_hist = result.perm_prob_hist + uint32(histcounts(prob.v, HistBin.EDGES)');
                result.perm_count = result.perm_count + 1;
            else
                result = net.result.ChiSquared(num_nets);
                result.chi2 = chi2;
                result.observed_gt_expected = observed_gt_expected;
                result.prob = prob;
            end
        end
    end
end

