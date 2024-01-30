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
        number_of_networks
    end
    
    methods
        function obj = ResultRank(permuted_network_results, number_of_network_pairs)
            if nargin > 0
                obj.nonpermuted_network_results = permuted_network_results.no_permutations;
                obj.permuted_network_results = permuted_network_results;
                obj.number_of_network_pairs = number_of_network_pairs;
            end
        end
        
        function ranking_result = rank(obj)
            import nla.TriMatrix nla.TriMatrixDiag

            ranking_result = obj.permuted_network_results.copy();
            
            for test_type = obj.permuted_network_results.test_methods
                if ~isequal(test_type, "no_permutations") && ~isequal(obj.permuted_network_results.test_display_name, "Cohen's D")

                    [ranking_statistic, probability, denominator] = obj.getTestParameters(test_type);
                    permutation_results = obj.permuted_network_results.permutation_results;
                    no_permutation_results = obj.nonpermuted_network_results;

                    % Eggebrecht ranking
                    ranking_result = obj.eggebrechtRank(test_type, permutation_results, no_permutation_results, ranking_statistic,...
                        probability, denominator, ranking_result);

                    if ~isequal(obj.permuted_network_results.test_name, "hypergeometric")
                        % Winkler Method ranking
                        ranking_result.(test_type).winkler_p_value = TriMatrix(...
                            obj.number_of_networks, TriMatrixDiag.KEEP_DIAGONAL...
                        );
                        ranking_result = obj.winklerMethodRank(test_type, permutation_results, no_permutation_results, ranking_statistic,...
                            probability, denominator, ranking_result);

                        % Westfall Young ranking
                        ranking_result.(test_type).westfall_young_p_value = TriMatrix(...
                            obj.number_of_networks, TriMatrixDiag.KEEP_DIAGONAL...
                        );
                        ranking_result = obj.westfallYoungMethodRank(test_type, permutation_results, no_permutation_results, ranking_statistic,...
                            probability, denominator, ranking_result);
                    end
                end
            end
        end
        
        function ranking = eggebrechtRank(obj, test_type, permutation_results, no_permutation_results, ranking_statistic,...
                        probability, denominator, ranking)
            
            for index = 1:numel(no_permutation_results.(probability).v)
                if isequal(test_type, "full_connectome")
                    combined_probabilities = [...
                        permutation_results.(strcat((probability), "_permutations")).v(:);...
                        no_permutation_results.(probability).v(index)...
                    ];
                else
                    combined_probabilities = [...
                        permutation_results.(strcat((probability), "_permutations")).v(index, :),...
                        no_permutation_results.(probability).v(index)...
                    ];
                end
                [~, sorted_combined_probabilites] = sort(combined_probabilities);
                ranking.(test_type).(probability).v(index) = find(...
                    squeeze(sorted_combined_probabilites) == 1 + denominator...
                    ) / (1 + denominator);
                    
                if ~isequal(obj.permuted_network_results.test_name, "hypergeometric")
                    combined_statistics = [permutation_results.(strcat((ranking_statistic), "_permutations")).v(:); no_permutation_results.(ranking_statistic).v(index)];
                    [~, sorted_combined_statistics] = sort(combined_statistics);
                    ranking.(test_type).(strcat("statistic_", (probability))).v(index) = find(...
                        squeeze(sorted_combined_statistics) == 1 + denominator...
                        ) / (1 + denominator);
                end
            end
        end

        function ranking = winklerMethodRank(obj, test_type, permutation_results, no_permutation_results, ranking_statistic,...
                        probability, denominator, ranking)

            max_statistic_array = max(abs(permutation_results.(strcat(ranking_statistic, "_permutations")).v));
            for index = 1:numel(no_permutation_results.(probability).v)
                ranking.(test_type).winkler_p_value.v(index) = sum(...
                    squeeze(max_statistic_array) >= abs(no_permutation_results.(ranking_statistic).v(index))...
                );
            end
            ranking.(test_type).winkler_p_value.v = ranking.(test_type).winkler_p_value.v ./ obj.permutations;
        end

        function ranking = westfallYoungMethodRank(obj, test_type, permutation_results, no_permutation_results, ranking_statistic,...
                        probability, denominator, ranking)

            % sort statistics in ascending order
            [sorted_no_permutation_results, sorted_statistic_indexes] = sort(...
                abs(no_permutation_results.(ranking_statistic).v)...
            );
            permutations_sorted_by_non_permuted = abs(...
                permutation_results.(strcat((ranking_statistic), "_permutations")).v(sorted_statistic_indexes, :)...
            );

            % Get max value of each permutation starting from max value of non-permuted statistics
            % Remove each row of permutations associated with non-permuted statistic
            % Get max of remaining. The last row of permutations should be with the smallest non-permuted statistic
            % This value gets ranked against its own permutations
            max_per_permutation_reducing_rows = zeros(...
                size(permutations_sorted_by_non_permuted, 1), size(permutations_sorted_by_non_permuted, 2)...
            );
            for row_index = size(permutations_sorted_by_non_permuted, 1):-1:2
                max_per_permutation_reducing_rows(row_index, :) = max(permutations_sorted_by_non_permuted(1:row_index, :));
            end
            max_per_permutation_reducing_rows(1, :) = permutations_sorted_by_non_permuted(1, :);

            ranking.(test_type).westfall_young_p_value.v = mean(...
                sorted_no_permutation_results < max_per_permutation_reducing_rows, 2);
            ranking.(test_type).westfall_young_p_value.v(sorted_statistic_indexes) =...
                ranking.(test_type).westfall_young_p_value.v;
        end 

        function [ranking_statistic, probability, denominator] = getTestParameters(obj, test_type)

            ranking_statistic = obj.permuted_network_results.ranking_statistic;
            probability = "p_value";
            denominator = obj.permutations * obj.number_of_network_pairs;
            % Only use these for within network pair and not Chi-Squared and Hypergeometric. 
            if isequal(test_type, "within_network_pair")
                denominator = obj.permutations;
                if ~any(...
                    strcmp(obj.permuted_network_results.test_name, obj.permuted_network_results.noncorrelation_input_tests)...
                )
                    ranking_statistic = strcat("single_sample_", ranking_statistic);
                    if isequal(obj.permuted_network_results.test_name, "wilcoxon")
                        ranking_statistic = "single_sample_ranksum_statistic";
                    end
                    probability = strcat("single_sample_", probability);
                end
            elseif isstruct(obj.permuted_network_results.within_network_pair) &&...
                any(strcmp(obj.permuted_network_results.test_name, obj.permuted_network_results.significance_test_names))
                % This condition catches Chi-Squared and Hypergeometric tests. We do not do within network ranking for them, we just copy
                % the full connectome ranking over. 

                obj.permuted_network_results.within_network_pair.p_value = obj.permuted_network_results.full_connectome.p_value;
            end
        end

        %% Getters for dependent properties
        % This takes the above statistic and gets the property to use its size to find the number of permutations
        function value = get.permutations(obj)
            value = size(obj.permuted_network_results.permutation_results.p_value_permutations.v, 2); 
        end

        function value = get.number_of_networks(obj)
            value = obj.permuted_network_results.no_permutations.p_value.size;
        end
        %%
    end
end