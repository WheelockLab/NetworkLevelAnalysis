function [D,R] = calc_correlationdist(zmat)
% Jiaxin Cindy Tu 2022.11.22
% Calculates the correlation for NxN matrix but excludes the diagonal

    % check that the matrix is the right format
    assert(size(zmat,1)==size(zmat,2));
    assert(length(size(zmat))==2);
    
    zmat(eye(size(zmat))==1) = NaN;% this calculation took too long (~25s)

    R = corr(zmat(1:end,:),'rows','pairwise');

    D = 1-R;
end