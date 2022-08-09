function [func_conn_residual, behavior_residual] = partialVariance(func_conn, behavior, covariates, type)
    import nla.* % required due to matlab package system quirks
    %% Control for Covariates %%
    % covariates are cov1, cov2... covN assumed to be column vectors
    %MW 1-3-2020
    num_roi = func_conn.size;
    num_subs = size(func_conn.v, 2);
    num_covariates = size(covariates, 2);

    mean_covariates = zeros(num_subs, num_covariates);
    % mean center covariates
    for i = 1:num_covariates
        cov = covariates(:, i); % raw
        cov_mean = cov - mean(cov); % mean center
        mean_covariates(:, i) = cov_mean;
    end

    % Partial out covariates from FC
    if type == PartialVarianceType.FCBX || type == PartialVarianceType.ONLY_FC
        % mean center the fc 
        fc_temp = func_conn.v;
        %fc_mean = bsxfun(@minus, fc_temp, mean(fc_temp, 2)); %mean centering fc makes it difficult to interpret - suggest not doing this
        fc_mean = fc_temp;

        % Estimate the residual fc partialling out covariates
        beta_fc = pinv(mean_covariates) * fc_mean';
        fcr = (fc_mean' - mean_covariates * beta_fc)';
    else
        fcr = func_conn.v;
    end
    
    func_conn_residual = TriMatrix(num_roi);
    func_conn_residual.v = fcr;

    if type == PartialVarianceType.FCBX || type == PartialVarianceType.ONLY_BX
        % Partial out covariates from Bx of interest
        mean_behavior = behavior - mean(behavior); %mean center
        beta_behavior = pinv(mean_covariates) * mean_behavior;
        behavior_residual = mean_behavior - mean_covariates * beta_behavior; % residual Bx
    else
        behavior_residual = behavior;
    end
end
