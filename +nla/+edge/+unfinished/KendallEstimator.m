classdef KendallEstimator < nla.edge.BaseTest
    %KendallEstimator Edge-level Kendall's tau estimator
    % TODO differs in what ways from kendall test?
    % TODO unfinished do not use
    % TODO unfinished do not use
    % TODO unfinished do not use
    % TODO unfinished do not use
    properties (Constant)
        name = "Kendall's tau (Estimator)"
    end
    
    methods
        function obj = KendallEstimator()
            import nla.* % required due to matlab package system quirks
            obj@nla.edge.BaseTest();
        end
        
        function result = run(obj, input_struct, previous_result)
            import nla.* % required due to matlab package system quirks
            
            behavior = permuteBehavior(input_struct.behavior, previous_result);
            y = input_struct.func_conn.v';
            n = numel(behavior);
            p2 = size(y, 2);
            n2const = n * (n-1) / 2;

            [xrank, xadj] = tiedrank(behavior, 1);
            [yrank, yadj] = tiedrank(y, 1);
            
            K = zeros(p2, 1); % save the obs. stat. for p-value computation

            a = sign(xrank' - repmat(xrank, 1, n));
            
            % method 6(broken)
            %a = flipud(tril(sign(xrank' - repmat(xrank, 1, n)), -1));
            %a = a(1:end -1, :);
            
            for j = 1:p2
                yrankj = yrank(:,j);
                %method 1
                %b = sign(yrankj' - repmat(yrankj, 1, n));
                %K(j) = sum(tril(a .* b, -1), 'all');
                
                %method 2
                %b = sign(bsxfun(@minus, yrankj', yrankj));
                %K(j) = sum(tril(a .* b, -1), 'all');
                
                %method 3
                %for k = 1:n - 1
                %    K(j) = K(j) + sum(a(k) .* sign(yrankj(k)-yrankj(k+1:n)));
                %end
                
                %method 4: 59.7s
                for k = 1:n-1
                    K(j) = K(j) + sum(sign(xrank(k) - xrank(k+1:n)) .* sign(yrankj(k) - yrankj(k+1:n)));
                end
                
                %method 5
                %for k = 1:n-1
                %    K(j) = K(j) + sum(a(k+1:n, 1) .* sign(yrankj(k)-yrankj(k+1:n)));
                %end
                
                % method 6(broken)
                %b = zeros(n - 1, n);
                %for k = 1:n-1
                %    b(k, k:n-1) = sign(yrankj(k)-yrankj(k+1:n));
                %end
                %K(j) = sum(tril(flipud(a .* b), -1), 'all');
                
                %method 7: 166s
                %b = sign(bsxfun(@minus, yrankj', yrankj));
                %for k = 1:n-1
                %    K(j) = K(j) + sum(a(k:n, k) .* b(k:n, k));
                %end
                
            end
            tau_vec = K ./ sqrt((n2const - xadj(1, 1)) .* (n2const - yadj(1, :)'));
            
            % Calculate the remaining p-values, except not the on-diag elements for
            % autocorrelation.  All cases with no ties and no removed missing values can
            % be computed based on a single null distribution.
            K_std = sqrt(n2const * (2 * n + 5) ./ 9);
            p_vec = normcdf(-(abs(K) - 1) ./ K_std);
            p_vec = 2 * p_vec;
            p_vec(p_vec > 1) = 1; % Don't count continuity correction at center twice
            
            result = obj.updateResult(input_struct, tau_vec, p_vec, previous_result);
        end
    end
end