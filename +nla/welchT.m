function [p_vec, t_vec, dof_vec] = welchT(x1, x2)
    %WELCHT 2-sample Welch T-test
    %% Prepare data
    x1_size = size(x1); 
    if x1_size(end) == 1
        x1_size(end) = []; 
    end
    
    x2_size = size(x2); 
    if x2_size(end) == 1
        x2_size(end) = []; 
    end
    
    ndim = length(x1_size);

    %% Means
    mu1 = mean(x1, ndim);
    mu2 = mean(x2, ndim);

    %% Ns
    n1 = x1_size(ndim);
    n2 = x2_size(ndim);

    %% SE2
    se1 = var(x1,0,ndim)./n1;
    se2 = var(x2,0,ndim)./n2;

    %% Unbiased estimator of variance; Satterthwaite
    d = sqrt(se1 + se2);

    %% T-statistic
    t_vec = (mu1 - mu2) ./ d;
    t_vec(~isfinite(t_vec)) = 0;

    %% Degrees-of-freedom; Welch-Satterthwaite
    dof_vec = ((se1 + se2) .^ 2) ./ (((se1 .^ 2) ./ (n1 - 1)) + ((se2 .^ 2) ./ (n2 - 1)));
    dof_vec(~isfinite(dof_vec)) = 0;

    %% P-values: 2-tailed p-value. to 1st approx, halve if want 1-tailed.
    p_vec = (tcdf(-abs(t_vec), dof_vec)) .* 2; 
    p_vec(~isfinite(p_vec)) = 0;
end

