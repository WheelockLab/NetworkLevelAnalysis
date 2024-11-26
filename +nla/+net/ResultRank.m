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
            import nla.TriMatrix nla.TriMatrixDiag nla.net.result.NetworkTestResult

            ranking_result = obj.permuted_network_results.copy();
            
            for test_method = obj.permuted_network_results.test_methods
                if ~isequal(test_method, "no_permutations") && ~isequal(obj.permuted_network_results.test_display_name, "Cohen's D")

                    ranking_statistic = obj.getTestParameters(test_method);
                    probability = NetworkTestResult().getPValueNames(test_method, obj.permuted_network_results.test_name);
                    permutation_results = obj.permuted_network_results.permutation_results;
                    no_permutation_results = obj.nonpermuted_network_results;

                    % Eggebrecht ranking
                    ranking_result = obj.eggebrechtRank(test_method, permutation_results, no_permutation_results, ranking_statistic,...
                        probability, ranking_result);

                    % Winkler Method ranking
                    ranking_result = obj.winklerMethodRank(test_method, permutation_results, no_permutation_results, ranking_statistic,...
                        probability, ranking_result);

                    % Westfall Young ranking
                    ranking_result = obj.westfallYoungMethodRank(test_method, permutation_results, no_permutation_results, ranking_statistic,...
                        probability, ranking_result);
                end
            end
        end
        
        function ranking = eggebrechtRank(obj, test_method, permutation_results, no_permutation_results, ranking_statistic,...
                probability, ranking)
                        
            for index = 1:numel(no_permutation_results.(strcat("uncorrected_", probability)).v)
                combined_probabilities = [...
                    permutation_results.(strcat((probability), "_permutations")).v(index, :),...
                    no_permutation_results.(strcat("uncorrected_", probability)).v(index)...
                ];
                combined_statistics = [...
                    permutation_results.(strcat((ranking_statistic), "_permutations")).v(index, :), no_permutation_results.(ranking_statistic).v(index)...
                ];

                legacy_probability = strcat("legacy_", probability);
                uncorrected_probability = strcat("uncorrected_", probability);

                % Legacy probability is from the old code and uses the calculated p-values from each individual test
                ranking.(test_method).(legacy_probability).v(index) = sum(...
                    abs(squeeze(combined_probabilities)) <= abs(no_permutation_results.(strcat("uncorrected_", probability)).v(index))...
                ) / (1 + obj.permutations);
                % Uncorrected probability is the p-value calculated from the individual test statistics (i.e. chi2, t-statistic, etc)
                if isequal(ranking.test_name, "hypergeometric")
                    ranking.(test_method).(uncorrected_probability).v(index) = sum(...
                        abs(squeeze(combined_statistics)) <= abs(no_permutation_results.(ranking_statistic).v(index))...
                    ) / (1 + obj.permutations);
                else
                    ranking.(test_method).(uncorrected_probability).v(index) = sum(...
                        abs(squeeze(combined_statistics)) >= abs(no_permutation_results.(ranking_statistic).v(index))...
                    ) / (1 + obj.permutations);
                end
            end
        end

        function ranking = winklerMethodRank(obj, test_method, permutation_results, no_permutation_results, ranking_statistic,...
                        probability, ranking)

            winkler_probability = strcat("winkler_", probability);
            max_statistic_array = max(abs(permutation_results.(strcat(ranking_statistic, "_permutations")).v));
            for index = 1:numel(no_permutation_results.(strcat("uncorrected_", probability)).v)
                ranking.(test_method).(winkler_probability).v(index) = sum(...
                    squeeze(max_statistic_array) >= abs(no_permutation_results.(ranking_statistic).v(index))...
                );
            end
            
            ranking.(test_method).(winkler_probability).v = ranking.(test_method).(winkler_probability).v ./ obj.permutations;
        end

        function ranking = westfallYoungMethodRank(obj, test_method, permutation_results, no_permutation_results, ranking_statistic,...
                        probability, ranking)

            % sort statistics in ascending order
            [sorted_no_permutation_results, sorted_statistic_indexes] = sort(...
                abs(no_permutation_results.(ranking_statistic).v)...
            );
            permutations_sorted_by_non_permuted = abs(...
                permutation_results.(strcat((ranking_statistic), "_permutations")).v(sorted_statistic_indexes, :)...
            );

            westfall_young_probability = strcat("westfall_young_", probability);

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

            ranking.(test_method).(westfall_young_probability).v = mean(sorted_no_permutation_results < max_per_permutation_reducing_rows, 2);
            
            ranking.(test_method).(westfall_young_probability).v(sorted_statistic_indexes) = ranking.(test_method).(westfall_young_probability).v;
        end 

        function ranking_statistic = getTestParameters(obj, test_method)

            ranking_statistic = obj.permuted_network_results.ranking_statistic;
            % Only use these for within network pair and not Chi-Squared and Hypergeometric. 
            if isequal(test_method, "within_network_pair") && ~any(...
                ismember(obj.permuted_network_results.test_name, obj.permuted_network_results.noncorrelation_input_tests)...
            )
                ranking_statistic = strcat("single_sample_", ranking_statistic);
                if isequal(obj.permuted_network_results.test_name, "wilcoxon")
                    ranking_statistic = "single_sample_ranksum_statistic";
                end
            end
        end

        %% Getters for dependent properties
        % This takes the above statistic and gets the property to use its size to find the number of permutations
        function value = get.permutations(obj)
            value = size(obj.permuted_network_results.permutation_results.two_sample_p_value_permutations.v, 2);
        end

        function value = get.number_of_networks(obj)
            value = obj.permuted_network_results.no_permutations.p_value.size;
        end
        %%
    end
end