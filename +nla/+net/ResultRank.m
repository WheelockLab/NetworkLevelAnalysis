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
        function obj = ResultRank(nonpermuted_network_results, permuted_network_results, number_of_network_pairs)
            if nargin > 0
                obj.nonpermuted_network_results = nonpermuted_network_results;
                obj.permuted_network_results = permuted_network_results;
                obj.number_of_network_pairs = number_of_network_pairs;
            end
        end
        
        function ranking_result = rank(obj)

            ranking_result = obj.permuted_network_results.copy();

            % Ranking
            if obj.permuted_network_results.test_display_name ~= "Cohen's D"
               ranking_result = obj.basicRank(ranking_result);
            end
        end
        
        function ranking = basicRank(obj, ranking)
            ranking_statistic = false;
            if obj.permuted_network_results.test_display_name ~= "Hypergeometric" % Hypergeomtric has no stat to rank
                ranking_statistic = obj.permuted_network_results.ranking_statistic;
            end

            % Full Connectome ranking
            ranking = obj.fullConnectomeRank(ranking, ranking_statistic);

            % Network Pair ranking
            ranking = obj.withinNetworkPairRank(ranking, ranking_statistic);

            % Winkler Method ranking
            ranking = obj.winklerMethodRank(ranking, ranking_statistic);

            % Westfall Young ranking
            ranking = obj.westfallYoungMethodRank(ranking, ranking_statistic);
        end
        
        function eggebrechtRank(obj)
            
        end

        function ranking = fullConnectomeRank(obj, ranking, ranking_statistic)

            probability = "p_value";
            no_permutation_result = obj.nonpermuted_network_results.no_permutations;
            permutation_results = obj.permuted_network_results.permutation_results;

            for index = 1:numel(no_permutation_result.(probability).v)
                % statistic ranking
                if obj.permuted_network_results.test_display_name ~= "Hypergeometric"
                    combined_statistics = [...
                        permutation_results.(strcat(ranking_statistic, "_permutations")).v(:);...
                        no_permutation_result.(ranking_statistic).v(index)...
                    ];
                    ranking.full_connectome.statistic_p_value.v(index) = sum(...
                        abs(squeeze(combined_statistics)) >= abs(no_permutation_result.(ranking_statistic).v(index))...
                        ) / (1 + obj.permutations * obj.number_of_network_pairs);
                end
                % p-value ranking
                combined_probabilities = [...
                    permutation_results.(strcat(probability, "_permutations")).v(:);...
                    no_permutation_result.(probability).v(index)...
                ];
                [~, sorted_combined_probabilites] = sort(combined_probabilities);
                ranking.full_connectome.p_value.v(index) = find(...
                    squeeze(sorted_combined_probabilites) == 1 + obj.permutations * obj.number_of_network_pairs...
                    ) / (1 + obj.permutations * obj.number_of_network_pairs);
            end
            ranking.full_connectome.d.v = obj.permuted_network_results.full_connectome.d.v;
        end

        function ranking = withinNetworkPairRank(obj, ranking, ranking_statistic)

            if ~any(strcmp(obj.permuted_network_results.test_name, obj.permuted_network_results.noncorrelation_input_tests))
                single_sample_probability = "single_sample_p_value";
                single_sample_statistic = strcat("single_sample_", ranking_statistic);
                
                no_permutation_result = obj.nonpermuted_network_results.no_permutations;
                permutation_results = obj.permuted_network_results.permutation_results;
                
                if obj.permuted_network_results.test_name == "wilcoxon"
                    single_sample_statistic = "single_sample_ranksum_statistic";
                end
                
                for index = 1:numel(no_permutation_result.(single_sample_probability).v)
                    % statistic ranking
                    combined_statistics = [...
                        permutation_results.(strcat(single_sample_statistic, "_permutations")).v(index, :),...
                        no_permutation_result.(single_sample_statistic).v(index)...
                    ];
                    ranking.within_network_pair.statistic_single_sample_p_value.v(index) = sum(...
                        abs(squeeze(combined_statistics)) >= abs(no_permutation_result.(single_sample_statistic).v(index))...
                        ) / (1 + obj.permutations);
                    
                        % p-value ranking
                    combined_probabilities = [...
                        permutation_results.(strcat(single_sample_probability, "_permutations")).v(index, :),...
                        no_permutation_result.(single_sample_probability).v(index)...
                    ];
                    [~, sorted_combined_probabilites] = sort(combined_probabilities);
                    ranking.within_network_pair.single_sample_p_value.v(index) = find(...
                        squeeze(sorted_combined_probabilites) == 1 + obj.permutations...
                        ) / (1 + obj.permutations);
                end
                
            elseif isstruct(obj.permuted_network_results.within_network_pair) &&...
                any(strcmp(obj.permuted_network_results.test_name, obj.permuted_network_results.noncorrelation_input_tests))
                % This condition catches Chi-Squared and Hypergeometric tests. We do not do within network ranking for them, we just copy
                % the full connectome ranking over. 
                ranking.within_network_pair.single_sample_p_value = ranking.full_connectome.p_value;
            end
            ranking.within_network_pair.d.v = obj.permuted_network_results.within_network_pair.d.v;
        end

        function ranking = winklerMethodRank(obj, ranking, ranking_statistic)
            
            permutation_results = obj.permuted_network_results.permutation_results;
            no_permutation_results = obj.nonpermuted_network_results.no_permutations;

            probability = "p_value";
            for index = 1:numel(no_permutation_results.(probability).v)
                % statistic ranking
                if obj.permuted_network_results.test_display_name ~= "Hypergeometric"
                    combined_statistics = [...
                        permutation_results.(strcat(ranking_statistic, "_permutations")).v(:);...
                        no_permutation_results.(ranking_statistic).v(index)...
                    ];

                    ranking.winkler_method.statistic_p_value.v(index) = sum(...
                        abs(squeeze(combined_statistics)) >= abs(no_permutation_results.(ranking_statistic).v(index))...
                    ) / (1 + obj.permutations);
                end

                % p-value ranking
                combined_probabilities = [...
                    permutation_results.(strcat(probability, "_permutations")).v(:);...
                    no_permutation_results.(probability).v(index)...
                ];
                [~, sorted_combined_probabilites] = sort(combined_probabilities);

                ranking.winkler_method.p_value.v(index) = find(...
                    squeeze(sorted_combined_probabilites) == 1 + obj.permutations...
                ) / (1 + obj.permutations);
            end
        end

        function ranking = westfallYoungMethodRank(obj, ranking, ranking_statistic)

            single_sample_statistic = ranking_statistic;

            permutation_results = obj.permuted_network_results.permutation_results;
            no_permutation_results = obj.nonpermuted_network_results.no_permutations;

            % Hypergeometric has no stat to rank
            if obj.permuted_network_results.test_display_name ~= "Hypergeometric"
                % sort statistics in ascending order
                [sorted_no_permutation_results, sorted_statistic_indexes] = sort(abs(no_permutation_results.(single_sample_statistic).v));
                permutations_sorted_by_non_permuted = abs(permutation_results.(strcat((single_sample_statistic), "_permutations")).v(sorted_statistic_indexes, :));

                max_per_permutation_reducing_rows = zeros(size(permutations_sorted_by_non_permuted, 1), size(permutations_sorted_by_non_permuted, 2));
                for row_index = size(permutations_sorted_by_non_permuted, 1):-1:2
                    max_per_permutation_reducing_rows(row_index, :) = max(permutations_sorted_by_non_permuted(1:row_index, :));
                end
                max_per_permutation_reducing_rows(1, :) = permutations_sorted_by_non_permuted(1, :);

                ranking.westfall_young.p_value.v = mean(sorted_no_permutation_results < max_per_permutation_reducing_rows, 2);
                ranking.westfall_young.p_value.v(sorted_statistic_indexes) = ranking.westfall_young.p_value.v;
            end
        end 

        % This takes the above statistic and gets the property to use its size to find the number of permutations
        function value = get.permutations(obj)
            value = size(obj.permuted_network_results.permutation_results.p_value_permutations.v, 2); 
        end
    end
end