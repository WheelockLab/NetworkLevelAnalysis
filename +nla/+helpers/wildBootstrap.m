function outY = wildBootstrap(inY, inX, inContrasts)
    
    %Inputs
    %inY - [n x m] matrix (n observations, m outputs per observation)
    %inX - [n x p] matrix (n observations, p covariates)
    %inContrasts - 1 x p matrix indicating which covariates we care about,
    %and which are noise. Model and resulting residulas will be calculated
    %by fitting a model only to noise

    %Fit linear model to only noise variables
    covariateIsNoise = inContrasts == 0;    
    xNoise = inX(:,covariateIsNoise);    
    pinvNoiseX = pinv(xNoise);    
    beta = pinvNoiseX * inY;    
    residual = inY - xNoise * beta;
    

    %TODO: make this flexible to choose different random dists to
    %hit residuals with
    %Currently is hardcoded to use rademacher distribution (ie +1
    %or -1 with equal likelihood
    numObs = size(inX,1);
    residualNoiseMultFactor = getRademacherVector(numObs);

    %Applying this noise factor to all fc edges for one
    %observation. Is this valid???

    outY = xNoise * beta + (residualNoiseMultFactor .* residual); %MATLAB can interpret dot multiplication as row-wise multiplication!


end
    
function outVec = getRademacherVector(numPts)
    %Returns a vector [numPts x 1] long of samples from a rademacher
    %distribution (ie +/-1 with equal probabilty)
    randVec = rand(numPts,1);
    vecIsPos = randVec>0.5;
    outVec = (vecIsPos - 0.5) * 2;

end

