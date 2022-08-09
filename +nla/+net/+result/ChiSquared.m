classdef ChiSquared < nla.net.BaseSigResult
    %CHISQUARED The output result of a Chi-squared test
    
    properties (Constant)
        name = "Chi-Squared"
        name_formatted = "\chi^2"
    end
    
    properties
        chi2
        within_np_chi2
    end
    
    methods
        function obj = ChiSquared(size)
            import nla.* % required due to matlab package system quirks
            % Superclass constructor
            obj@nla.net.BaseSigResult(size);
            
            obj.chi2 = TriMatrix(size, TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            import nla.* % required due to matlab package system quirks
            merge@nla.net.BaseResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
            
            %% Within Net-Pair statistics (withinNP)
            num_nets = net_atlas.numNets();
            chi2 = TriMatrix(num_nets, TriMatrixDiag.KEEP_DIAGONAL);
            observed_gt_expected = TriMatrix(num_nets, 'logical', TriMatrixDiag.KEEP_DIAGONAL);
            
            for row = 1:num_nets
                for col = 1:row
                    % get permuted and nonpermuted edge-level probabilities
                    i_row = net_atlas.nets(row).indexes;
                    i_col = net_atlas.nets(col).indexes;
                    prob_net = edge_result_nonperm.prob_sig.get(i_row, i_col);
                    prob_net_perm = edge_result.prob_perm.get(i_row, i_col);
                    
                    observed_sig = sum(prob_net);
                    expected_sig = sum(prob_net_perm, 'all') ./ double(obj.perm_count);
                    chi2.set(row, col, ((observed_sig - expected_sig) .^ 2) .* ((expected_sig .^ -1)));
                    observed_gt_expected.set(row, col, observed_sig > expected_sig);
                end
            end
            
            chi2.v(~observed_gt_expected.v) = 0;
            chi2.v(~isfinite(chi2.v)) = 0;
            
            obj.within_np_chi2 = chi2;
            obj.within_np_prob.v = chi2cdf(chi2.v, 1, 'upper');
        end
    end
end
