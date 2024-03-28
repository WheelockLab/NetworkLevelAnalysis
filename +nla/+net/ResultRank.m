classdef ResultRank < handle
    % RESULTRANK Class to take permutation results and rank them. This used to be done incrementally. It"s a little hacky, beware
    % This class does a classic permutation based ranking of results. The "observed" (nonpermuted) result is appended to the results
    % of all the permuted results. All of these results are sorted and then searched for the observed result. Where this result is located
    % in the sorted array ends up being the p-value.

    properties
        nonpermuted_network_results % The results from the network tests (these are the ones being tested)
        permuted_network_results % The results from the network tests with all the paramters permuted over and over
        number_of_network_pairs % The number of network pairs in the atlas being used
    end
    
    properties (Dependent)
        permutations
    end
    
    methods
        function obj = ResultRank(nonpermuted_network_results, permuted_network_results, statistical_ranking, number_of_network_pairs)
            if nargin > 0
                obj.nonpermuted_network_results = nonpermuted_network_results;
                obj.permuted_network_results = permuted_network_results;
                obj.statistical_ranking = statistical_ranking;
                obj.number_of_network_pairs = number_of_network_pairs;
            end
        end
        
        function ranking_result = rank(obj)
            % Copy the nonpermuted network results to put the permuted results into after ranking
            ranking_result = obj.nonpermuted_network_results.copy();
%             ranking_result.perm_prob_hist = zeros(nla.HistBin.SIZE, "uint32");
            % Copying doesn"t copy all the properties? So we rewrite the permutations
            % Also, permutations is as cast as an unsigned 32-bit int, so we have to do that here #LegacyCodeIssues
            % ranking_result.perm_count = uint32(obj.permutations);
            
            % Experiment wide ranking
            if obj.permuted_network_results.test_display_name ~= "Cohen's D"
               ranking_result = obj.basicRank(ranking_result);
            end
        end
        
        function ranking = basicRank(obj, ranking)
            if obj.permuted_network_results.test_display_name ~= "Hypergeometric"
                ranking_statistic = obj.permuted_network_results.ranking_statistic;
            end
            % Experiment Wide ranking
            probability = "p_value";
            for index = 1:numel(obj.nonpermuted_network_results.no_permutations.(probability).v)
                % statistic ranking
                if obj.permuted_network_results.test_display_name ~= "Hypergeometric"
                    combined_statistics = [obj.permuted_network_results.permutation_results.(strcat(ranking_statistic, "_permutations")).v(:); obj.nonpermuted_network_results.no_permutations.(ranking_statistic).v(index)];
                    ranking.full_connectome.statistic_p_value.v(index) = sum(abs(squeeze(combined_statistics)) >= abs(obj.nonpermuted_network_results.no_permutations.(ranking_statistic).v(index))) / (1 + obj.permutations * obj.number_of_network_pairs);
                end
                % p-value ranking
                combined_probabilities = [obj.permuted_network_results.permutation_results.(strcat(probability, "_permutations")).v(:); obj.nonpermuted_network_results.no_permutations.(probability).v(index)];
                [~, sorted_combined_probabilites] = sort(combined_probabilities);
                ranking.full_connectome.p_value.v(index) = find(squeeze(sorted_combined_probabilites) == 1 + obj.permutations * obj.number_of_network_pairs) / (1 + obj.permutations * obj.number_of_network_pairs);
            end

            % Network Pair ranking
            if isstruct(obj.permuted_network_results.within_network_pair) && isfield(obj.permuted_network_results.within_network_pair, "single_sample_p_value")
                single_sample_probability = "single_sample_p_value";
                single_sample_statistic = strcat("single_sample_", ranking_statistic);
                for index = 1:numel(obj.nonpermuted_network_results.no_permutations.(single_sample_probability).v)
                    % statistic ranking
                    combined_statistics = [obj.permuted_network_results.permutation_results.(strcat(single_sample_statistic, "_permutations")).v(index, :), obj.nonpermuted_network_results.no_permutations.(single_sample_statistic).v(index)];
                    ranking.within_network_pair.single_sample_statistic_p_value.v(index) = sum(abs(squeeze(combined_statistics)) >= abs(obj.nonpermuted_network_results.no_permutations.(single_sample_statistic).v(index))) / (1 + obj.permutations);
                    % p-value ranking
                    combined_probabilities = [obj.permuted_network_results.permutation_results.(strcat(single_sample_probability, "_permutations")).v(index, :), obj.nonpermuted_network_results.no_permutations.(single_sample_probability).v(index)];
                    [~, sorted_combined_probabilites] = sort(combined_probabilities);
                    ranking.within_network_pair.single_sample_p_value.v(index) = find(squeeze(sorted_combined_probabilites) == 1 + obj.permutations) / (1 + obj.permutations);
                end
            elseif isstruct(obj.permuted_network_results.within_network_pair) && any(strcmp(obj.permuted_network_results.test_name, obj.permuted_network_results.noncorrelation_input_test_names))
                % This condition catches Chi-Squared and Hypergeometric tests. We do not do within network ranking for them, we just copy
                % the full connectome ranking over. 
                obj.permuted_network_results.within_network_pair.single_sample_p_value = obj.permuted_network_results.full_connectome.p_value;
            end
        end
        
        function value = get.permutations(obj)
            statistic = obj.permuted_network_results.ranking_statistic; % This is a string that is the statistic of measurement
            value = size(obj.permuted_network_results.permutation_results.(strcat(statistic, "_permutations")).v, 2); % This takes the above statistic and gets the property to use its size to find the number of permutations
        end
    end
end