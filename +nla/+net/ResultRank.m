classdef ResultRank < handle
    % RESULTRANK Class to take permutation results and rank them. This used to be done incrementally. It"s a little hacky, beware
    
    properties
        nonpermuted_network_results % The results from the network tests (these are the ones being tested)
        permuted_network_results % The results from the network tests with all the paramters permuted over and over
        statistical_ranking % Are we ranking by statistics (TRUE) or probabilities (FALSE)
        number_of_network_pairs % The number of network pairs in the atlas being used
        significance_function % The function used to rank the statistics (This is a property on the permuted results object)
    end
    
    properties (Dependent)
        permutations
    end

    properties (Constant)
        statistic_map = containers.Map(...
            ["chi2_permutations", "ks_permutations", "single_sample_ks_permutations", "t_permutations",...
            "single_sample_t_permutations", "z_permutations", "single_sample_w_permutations"],...
            ["chi2", "ks", "ss_ks", "t", "ss_t", "z", "ss_w"]...
        );
    end
    
    methods
        function obj = ResultRank(nonpermuted_network_results, permuted_network_results, number_of_network_pairs)
            if nargin > 0
                obj.nonpermuted_network_results = nonpermuted_network_results;
                obj.permuted_network_results = permuted_network_results;
                obj.number_of_network_pairs = number_of_network_pairs;
                obj.significance_function = permuted_network_results.significance_function;
            end
        end
        
        function ranking_result = rank(obj)
            % Copy the nonpermuted network results to put the permuted results into after ranking
            ranking_result = obj.nonpermuted_network_results.copy();
%             ranking_result.perm_prob_hist = zeros(nla.HistBin.SIZE, "uint32");
            % Copying doesn"t copy all the properties? So we rewrite the permutations
            % Also, permutations is as cast as an unsigned 32-bit int, so we have to do that here #LegacyCodeIssues
            ranking_result.perm_count = uint32(obj.permutations);
            
            % Experiment wide ranking
            if obj.permuted_network_results.test ~= "Cohen's D"
               ranking_result = obj.basicRank(ranking_result);
            end
        end
        
        function ranking = basicRank(obj, ranking)
            % Experiment Wide ranking
            if obj.permuted_network_results.test ~= "Hypergeometric"
                statistic = obj.permuted_network_results.statistic;
                nonpermuted_statistic = obj.get_nonpermuted_statistic(statistic);
            end
            permuted_probabilites = "probability_permutations";
            nonpermuted_probability = "prob";
            for index = 1:numel(obj.nonpermuted_network_results.(nonpermuted_probability).v)
                % statistic ranking
                if obj.permuted_network_results.test ~= "Hypergeometric"
                    combined_statistics = [obj.permuted_network_results.(statistic).v(:); obj.nonpermuted_network_results.(nonpermuted_statistic).v(index)];
                    ranking.perm_stat_ew.v(index) = sum(abs(squeeze(combined_statistics)) >= abs(obj.nonpermuted_network_results.(nonpermuted_statistic).v(index))) / (1 + obj.permutations * obj.number_of_network_pairs);
                end
                % p-value ranking
                combined_probabilities = [obj.permuted_network_results.(permuted_probabilites).v(:); obj.nonpermuted_network_results.(nonpermuted_probability).v(index)];
                [~, sorted_combined_probabilites] = sort(combined_probabilities);
                ranking.perm_prob_ew.v(index) = find(squeeze(sorted_combined_probabilites) == 1 + obj.permutations * obj.number_of_network_pairs) / (1 + obj.permutations * obj.number_of_network_pairs);
            end

            % Network Pair ranking
            if any(strcmp(["Welch's T", "Student's T", "Wilcoxon rank-sum", "Kolmogorov-Smirnov"], obj.permuted_network_results.test))
                permuted_single_sample_statistic = obj.permuted_network_results.single_sample_statistic;
                nonpermuted_single_sample_statistic = obj.get_nonpermuted_statistic(permuted_single_sample_statistic);
                permuted_probabilites = "single_sample_probability_permutations";
                nonpermuted_probability = "ss_prob";
                for index = 1:numel(obj.nonpermuted_network_results.(nonpermuted_probability).v)
                    % statistic ranking
                    combined_statistics = [obj.permuted_network_results.(permuted_single_sample_statistic).v(index, :), obj.nonpermuted_network_results.(nonpermuted_single_sample_statistic).v(index)];
                    [sorted_combined_statistics, ~] = sort(combined_statistics);
                    ranking.within_np_stat.v(index) = sum(abs(squeeze(sorted_combined_statistics)) >= abs(obj.nonpermuted_network_results.(nonpermuted_single_sample_statistic).v(index))) / (1 + obj.permutations);
                    % p-value ranking
                    combined_probabilities = [obj.permuted_network_results.(permuted_probabilites).v(index, :), obj.nonpermuted_network_results.(nonpermuted_probability).v(index)];
                    [~, sorted_combined_probabilites] = sort(combined_probabilities);
                    ranking.within_np_prob.v(index) = find(squeeze(sorted_combined_probabilites) == 1 + obj.permutations) / (1 + obj.permutations);
                end
            end
        end
        
        function value = get.permutations(obj)
            statistic = obj.permuted_network_results.statistic; % This is a string that is the statistic of measurement
            value = size(obj.permuted_network_results.(statistic).v, 2); % This takes the above statistic and gets the property to use its size to find the number of permutations
        end

        function value = get_nonpermuted_statistic(obj, statistic)
            value = obj.statistic_map(statistic);
        end
    end
end