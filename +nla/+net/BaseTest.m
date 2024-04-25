classdef BaseTest < nla.Test
    %BASETEST Base class of tests performing net-level analysis
    % The intended behavior of the run function of a net-level test is that
    % it creates a new result object on the nonpermuted run and accepts
    % said result as previous_result on all subsequent permuted runs,
    % modifying it.
    
    methods
        function obj = BaseTest()
        end 
    end
    
    methods (Abstract)
        run(obj, input_struct, edge_result, net_atlas, previous_result)
    end
    
    methods (Static)
        function inputs = requiredInputs()
            % Inputs that must be provided to run the test
            inputs = {nla.inputField.Integer('behavior_count', 'Test count:', 1, 1, Inf),...
                nla.inputField.Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1)};
        end
        
        function result = rank(net_atlas, result, input_struct, sig_func, stat, stat_prob, stat_perm, stat_prob_perm,...
            stat_ss, stat_ss_prob, stat_ss_perm, stat_ss_prob_perm)
            %RANK Rank test statistics against non-permuted equivelents and
            % add on to the relevant ranking fields (later used to
            % calculate p-values, in the result merge() step)
            import nla.ACCURACY_MARGIN
            
            stat_ranking = false;
            if ~isfield(input_struct, 'ranking_method') || input_struct.ranking_method == nla.RankingMethod.TEST_STATISTIC
                stat_ranking = true;
            end
            
            if (~islogical(stat) && ~islogical(stat_perm)) || (~islogical(stat_prob) && ~islogical(stat_prob_perm))
                stat_ranking_perm = (stat_ranking && ~islogical(stat)) || islogical(stat_prob);
                % Sum the number of permutations which produce a statistic
                % equal to or greater than the non-permuted statistic
                % We will later divide this by the total number of
                % permutations to calculate the p value.
                % Fisher, R.A. (1935) The Design of Experiments, New York: Hafner
                if stat_ranking_perm
                    sig = sig_func(stat_perm.v, stat.v - ACCURACY_MARGIN);
                else
                    sig = stat_prob_perm.v <= stat_prob.v + ACCURACY_MARGIN;
                end
                result.perm_rank.v = result.perm_rank.v + uint64(sig);
                
                for i = 1:net_atlas.numNetPairs()
                    % Similar to the previous ranking, but experiment-wide
                    % (ranking a network's test stat among all permutations
                    % of all networks). Code is subtly different from
                    % previous usage, refactor with care.
                    if stat_ranking_perm
                        sig_ew = sig_func(stat_perm.v, stat.v(i) - ACCURACY_MARGIN);
                    else
                        sig_ew = stat_prob_perm.v <= stat_prob.v(i) + ACCURACY_MARGIN;
                    end
                    result.perm_rank_ew.v(i) = result.perm_rank_ew.v(i) + sum(uint64(sig_ew));
                end
            end
            
            % rank single-sample statistics, if provided
            if (~islogical(stat_ss) && ~islogical(stat_ss_perm)) || (~islogical(stat_ss_prob) && ~islogical(stat_ss_prob_perm))
                if (stat_ranking && ~islogical(stat_ss)) || islogical(stat_ss_prob)
                    ss_sig = sig_func(stat_ss_perm.v, stat_ss.v - ACCURACY_MARGIN);
                else
                    ss_sig = stat_ss_prob_perm.v <= stat_ss_prob.v + ACCURACY_MARGIN;
                end
                result.within_np_rank.v = result.within_np_rank.v + uint64(ss_sig);
            end
            
            % update histogram
            if ~islogical(stat_prob_perm)
                result.perm_prob_hist = result.perm_prob_hist + uint32(histcounts(stat_prob_perm.v, nla.HistBin.EDGES)');
            end
            
            result.perm_count = result.perm_count + 1;
        end
    end
end
