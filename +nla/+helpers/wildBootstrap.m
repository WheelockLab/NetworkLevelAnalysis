function outY = wildBootstrap(inY, inX, inContrasts, origBeta, origResidual)
    
    %Inputs
    %inY - [n x m] matrix (n observations, m outputs per observation)
    %inX - [n x p] matrix (n observations, p covariates)
    %inContrasts - 1 x p matrix indicating which covariates we care about,
    %and which are noise. Model and resulting residuals will be calculated
    %by fitting a model only to noise    
    %origBeta (optional) - p x 1 vector of beta weights if we've already fit the
    %linear model
    %origResidual (optional) - n x 1 vector of residuals if we've already fit the
    %linear model

    
    %If beta and residual not provided, calculate them now
    
    if nargin <=3
        
        %Fit linear model to only noise variables - incorrect! fit to all, then
        %re-add betas for noise variables
    %     covariateIsNoise = inContrasts == 0;    
    %     xNoise = inX(:,covariateIsNoise);    
    %     pinvNoiseX = pinv(xNoise);    
    %     beta = pinvNoiseX * inY;    
    %     residual = inY - xNoise * beta;

        %Fit linear model to all variables
        pinvX = pinv(inX);
        beta = pinvX * inY;
    else
        beta = origBeta;
    end
    
    %if residual not provided, calculate it from x, y, and beta
    if nargin <=4
        residual = inY - inX * beta;
    else
        residual = origResidual;
    end
    
    %generate new values by using betas from noise only, and adding in
    %random multiplier of residual
    numObs = size(inX,1);
    residualNoiseMultFactor = getRademacherVector(numObs);
    
    covariateIsNoise = inContrasts == 0;
    outY = inX(:,covariateIsNoise) * beta(covariateIsNoise,:) + (residualNoiseMultFactor .* residual);
    
end
    
function outVec = getRademacherVector(numPts)
    %Returns a vector [numPts x 1] long of samples from a rademacher
    %distribution (ie +/-1 with equal probabilty)
    randVec = rand(numPts,1);
    vecIsPos = randVec>0.5;
    outVec = (vecIsPos - 0.5) * 2;

end

