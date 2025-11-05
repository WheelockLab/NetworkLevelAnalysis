
function [isSignificant,adjusted_pvals,alpha]= bonferroni_holm(pvals,optional_alpha)
    %% bonferroni_holm, bonferroni_holm(pvals), bonferroni_holm(pvals, alpha);
    % Corrects for testing multiple hypotheses.
    % This method is more powerful, but less conservative than the Bonferroni method.
    % Fixed so that adjusted p-values do not exceed 1.
    % Holm, S. (1979). A simple sequentially rejective multiple test procedure. Scandinavian Journal of Statistics, 6(2), 65-70.
    % Ellen Zakreski 2018, MATLAB 2019
    %
    % ---examples----------------------------------------------------------
    % bonferroni_holm([0.01; 0.15; 0.04]) <-corrects for 3 tests, alpha = 0.05 (default)
    %
    % bonferroni_holm([0.15; 0.04; 0.65; 0.08], 0.10) <-corrects for 4 tests, alpha = 0.10
    %
    % ---inputs------------------------------------------------------------
    % 1. pvals: Non-empty numeric array (any size) of 1 or more raw/unadjusted p-values.
    %         To correct for multiple tests, include p values from all hypotheses tested (significant or not).
    %
    % 2. (optional) alpha: A number between 0 and 1 (inclusive)
    %         indicating desired significance level. Default alpha = 0.05
    %
    % ---outputs-----------------------------------------------------------
    % 1. isSignificant: Logical array (same size as pvals) indicating
    %         which hypotheses are still significant after FWE correction.
    %         If isSignificant(n) is true, then reject the nth null hypotheses.
    %
    % 2. adjusted_pvals: numeric array (same size as pvals) of p-values adjusted for FWE
    %
    % 3. alpha: a number indicating significance level
    
    %% validate input
    narginchk(1,2)
    function bonferroni_holm_assert_value_propbability(value, name)
        %e.g. bonferroni_holm_assert_number_propbability(pvals, 'elements in pvals');
        %e.g. bonferroni_holm_assert_number_propbability(alpha, 'alpha');
        assert(isnumeric(value),'bonferroni_holm:invalid_probability','%s must must be numeric',name);
        assert(~isempty(value),'bonferroni_holm:invalid_probability','%s cannot be empty.',name);
        vec=reshape(value,numel(value),1);
        assert(all(isreal(vec)),'bonferroni_holm:invalid_probability','%s must must be real.',name);
        in_range = vec>=0 & vec<=1;
        if ~all(in_range)
            assert(~any(isnan(vec)),'bonferroni_holm:invalid_probability','%s cannot be NaN.',name);
            error('bonferroni_holm:invalid_probability','%s must be between 0 and 1 (inclusive).',name);
        end
    end
    
    bonferroni_holm_assert_value_propbability(pvals, 'pvals'); % calls function nested within this function
    if nargin==2
        bonferroni_holm_assert_value_propbability(optional_alpha,'optional_alpha'); % calls function nested within this function
        alpha=optional_alpha;
    else
        alpha=0.05;
    end
    %% done checking input
    % get a column vector of p values.
    C = numel(pvals);
    pval_vector = reshape(pvals,C,1);
    % rank pvalues from smallest to largest
    [~,rnk_ind] = sort(pval_vector,'ascend');
    [~,rnk] = sort(rnk_ind,'ascend');
    % get adjusted (corrected) p-values
    adjusted_pval_vector = (C - rnk + 1).*pval_vector;
    % if you have some large p-values and/or many hypotheses it is possible
    % to get adjusted p-values > 1.
    % these should be treated as 1.
    adjusted_pval_vector(adjusted_pval_vector>1) = 1;
    
    %% determine which hypothesese to reject (i.e. significant p-values)
    accept_null_vector = adjusted_pval_vector >= alpha;
    if any(accept_null_vector)
        % find first lowest p value that does not pass significance, and accept all hypotheses with a greater p-value
        rnk_first_null_to_accept = min(rnk(accept_null_vector));
        % accept null of for all hypotheses with p values larger than the first ranked pvalue that does not pass the test
        accept_null_vector(rnk>=rnk_first_null_to_accept) = true;
    end
    isSignificant_vector = ~accept_null_vector;
    
    %% reshape output to match size of inputted pvals
    adjusted_pvals = reshape(adjusted_pval_vector, size(pvals));
    isSignificant  = reshape(isSignificant_vector, size(pvals));
end
