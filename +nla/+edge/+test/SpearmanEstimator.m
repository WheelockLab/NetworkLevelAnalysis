classdef SpearmanEstimator < nla.edge.BaseTest
    %SPEARMANESTIMATOR Fast estimator of the edge-level Spearman correlation
    %   Similar to the internal implementation of SpearmanTest, but removes
    %   an expensive call to tiedrank. This causes it to run several times
    %   faster, but produce slightly incorrect output (on the order of 1e-4
    %   for rho-values and 1e-5 for p-values), at the ROI-pair level. This
    %   error is passed on to network-level test results (P values) at differing
    %   significance + distribution depending on the number of
    %   permutations, ex: at 100 permutations the error (difference between
    %   Spearman estimator and test) is ~ 1e-3 and only present in a few
    %   networks, at 10k permutations the error is 1e-4 and distributed
    %   more evenly among most networks. The total amount of error(sum of
    %   error) also decreases overall with the increase in permutation count.
    %
    %   Based on this, SpearmanEstimator is recommended for exploratory
    %   research and using SpearmanTest is recommended for publication.
    properties (Constant)
        name = "Spearman's rho (Estimator)"
        coeff_name = "Spearman's rho (Estimated, Fisher-Z Transformed)"
    end
    
    methods
        function obj = SpearmanEstimator()
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct)
            %% input
            y = input_struct.func_conn.v';
            
            %% Parameters
            n = numel(input_struct.behavior);%,p1
            p2 = size(y, 2);
            n3const = (n + 1) * n * (n - 1) ./ 3;
            % rho = zeros(p1,p2,'single');
            % pval = zeros(p1,p2,'single');
            
            %% Sort
            % tiedrank is a type of ranking where if two elements have the 
            % same score their rank is computed as the average of how they
            % would otherwise be ranked.
            [x, xadj] = tiedrank(input_struct.behavior, 0);
            % These lines create a Subject x ROIpairs matrix ranking the
            % subjects by ROI pair correlation. Basically, for each ROI pair,
            % rank the subjects by their fc number in that ROI pair (smallest
            % FC #= 1, largest = 965 or whatever), and place the rank #s where
            % the scores were. So if subject had the lowest number at that
            % ROI pair, he would have score 1.
            % Code is similar to this commented-out line, but without tied
            % ranks, which is faster
            % [y,yadj] = tiedrank(y,0);
            [~, idx] = sort(y);
            for j = 1:p2
                y(idx(:,j),j) = [1:n]';
            end
            
            %% Calc rho and p-val
            % for each subject: rank of subject's behavior score - their rank
            % in each ROI pair(make a new array of same dimensions as y).
            % Then sum all of the ROI scores up for each ROI, across subjects.
            % Resulting array has 1 score for each ROI pair.
            % for i = 1:p1    % for each column in X
            D = sum(bsxfun(@minus, x, y) .^ 2); % sum((xranki - yrankj).^2);
            
            % meanD = (n3const - (xadj+yadj)./3) ./ 2;
            % stdD = sqrt((n3const./2 - xadj./3)*(n3const./2 - yadj./3)./(n-1));
            % % ASSUMING yadj==0!
            meanD = (n3const - (xadj) ./ 3) ./ 2;
            stdD = sqrt((n3const ./ 2 - xadj ./ 3) * (n3const ./ 2) ./ (n - 1));
            
            % rho
            rho_vec = ((meanD - D) ./ (sqrt(n - 1) * stdD))';

            % p-val: Use a t approximation.
            t = Inf * sign(rho_vec);
            ok = (abs(rho_vec) < 1);
            t(ok) = rho_vec(ok) .* sqrt((n - 2) ./ (1 - rho_vec(ok) .^ 2));
            
            result = obj.composeResult(input_struct.net_atlas, nla.fisherR2Z(rho_vec), (2 * tcdf(-abs(t), n - 2)), input_struct.prob_max);
        end
    end
end

