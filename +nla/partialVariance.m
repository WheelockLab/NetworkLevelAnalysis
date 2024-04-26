function [func_conn_residual, behavior_residual] = partialVariance(func_conn, behavior, covariates, type)
    %PARTIALVARIANCE Perform partial variance, removing specified
    %   covariates and returning residuals
    %   func_conn: NroisxNroisxNsubs functional connectivity matrix
    %   behavior: Nsubsx1 behavioral score vector
    %   covariates: NsubsxNcovs covariate vectors
    %   type: PartialVarianceType enumeration value specifying whether to
    %       factor covariates from fc, behavior, or both
    %   func_conn_residual: residual of functional connectivity, if
    %       factoring covariates from it
    %   behavior_residual: residual of behavioral scores, if factoring
    %       covariates from them
    %% Control for Covariates %%
    % covariates are cov1, cov2... covN assumed to be column vectors
    %MW 1-3-2020
    import nla.PartialVarianceType

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
    
    func_conn_residual = nla.TriMatrix(num_roi);
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
