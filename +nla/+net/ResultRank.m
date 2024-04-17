classdef ResultRank < handle
    % RESULTRANK Class to take permutation results and rank them. This used to be done incrementally. It"s a little hacky, beware
    % This class does a classic permutation based ranking of results. The "observed" (nonpermuted) result is appended to the results
    % of all the permuted results. All of these results are sorted and then searched for the observed result. Where this result is located
    % in the sorted array ends up being the p-value.

    properties
        nonpermuted_network_results % The results from the network tests (these are the ones being tested)
        permuted_network_results % The results from the network tests with all the paramters permuted over and over
        statistical_ranking % Are we ranking by statistics (TRUE) or probabilities (FALSE)
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
        
        function obj = rank(obj)
            % Experiment wide ranking
            % If full_connectome was not selected, obj.permuted_network_results.full_connectome = false

            % The non-permuted results need to be placed into the "no_permutations" section of the obj.permuted_network_result
            % The obj.nonpermuted_network_results can then be eliminated as an argument
            if isstruct(obj.permuted_network_results.full_connectome)
                for index = 1:numel(obj.nonpermuted_network_results.no_permutations.p_value.v)

                    combined_probabilities = [obj.permuted_network_results.permutation_results.p_value_permutations.v(:);...
                        obj.nonpermuted_network_results.no_permutations.p_value.v(index)];
                    % If we could get matlab to not change the value/precision on sort, we could use binary search and 
                    % decrease sorting from O(n) -> O(log(n))
                    % This would make a very large speed increase (especially for large n) each iteration.
                    % TODO: the above
                    [~, sorted_combined_probabilites] = sort(combined_probabilities);

                    obj.permuted_network_results.full_connectome.p_value.v(index) =...
                        find(squeeze(sorted_combined_probabilites) == 1 + obj.permutations * obj.number_of_network_pairs) /...
                        (1 + obj.permutations * obj.number_of_network_pairs);
                end
            end

            % Network Pair ranking
            if isstruct(obj.permuted_network_results.within_network_pair) &&...
                isfield(obj.permuted_network_results.within_network_pair, "single_sample_p_value")

                for index = 1:numel(obj.nonpermuted_network_results.no_permutations.p_value.v)
                    combined_probabilities = [obj.permuted_network_results.permutation_results.single_sample_p_value_permutations.v(index, :),...
                        obj.nonpermuted_network_results.no_permutations.p_value.v(index)];
                    [~, sorted_combined_probabilites] = sort(combined_probabilities);
                    obj.permuted_network_results.within_network_pair.single_sample_p_value.v(index) = find(...
                        squeeze(sorted_combined_probabilites) == 1 + obj.permutations) /...
                        (1 + obj.permutations);
                end
            elseif isstruct(obj.permuted_network_results.within_network_pair) &&...
                any(strcmp(obj.permuted_network_results.test_name, obj.permuted_network_results.significance_test_names))
                % This condition catches Chi-Squared and Hypergeometric tests. We do not do within network ranking for them, we just copy
                % the full connectome ranking over. 

                obj.permuted_network_results.within_network_pair.single_sample_p_value = obj.permuted_network_results.full_connectome.p_value;
            end
        end
        
        function value = get.permutations(obj)
            value = obj.permuted_network_results.permutation_count;    
        end
    end
end