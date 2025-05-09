classdef TestPool < nla.DeepCopyable
    %TESTPOOL Pool of edge and net tests to be run
    
    properties
        edge_test = false
        net_tests = {}
        data_queue = false
    end

    properties (Constant)
        correlation_input_tests = ["kolmogorov_smirnov", "students_t", "welchs_t", "wilcoxon"]
    end

    methods (Access = private)

        function [number_processes, blocks] = initializeParallelPool(obj, number_permutations)
            % get current parallel pool or start a new one
            p = gcp;
            number_processes = p.NumWorkers;
            
            % blocks of iteration to be handled by each process
            if number_permutations < number_processes
                blocks = 1:(number_permutations + 1);
                number_processes = number_permutations;
            else
                blocks = uint32(linspace(1, double(number_permutations + 1), number_processes + 1));
            end
        end
    end
    
    methods
        
        function obj = TestPool()
            obj.edge_test = nla.edge.test.Pearson();
        end
        
        function result = runPerm(obj, edge_input_struct, net_input_struct, network_atlas, nonpermuted_edge_test_results,...
            nonpermuted_network_test_results, num_perms, perm_seed, separate_network_and_edge_tests)
            
            if ~exist('perm_seed', 'var')
                perm_seed = false;
            end
            
            if ~exist('separate_network_and_edge_tests', 'var')
                separate_network_and_edge_tests = false;
            end

            if isequal(separate_network_and_edge_tests, false)
                [permuted_edge_test_results, permuted_network_test_results] = obj.runEdgeAndNetPerm(edge_input_struct,...
                    net_input_struct, network_atlas, nonpermuted_edge_test_results, num_perms, perm_seed);
            else
                [permuted_edge_test_results, permuted_network_test_results] = obj.runPermSeparateEdgeAndNet(edge_input_struct,...
                    net_input_struct, network_atlas, num_perms, perm_seed);
            end
            
            ranked_permuted_network_test_results = obj.collateNetworkPermutationResults(nonpermuted_edge_test_results, network_atlas,...
                nonpermuted_network_test_results, permuted_network_test_results, net_input_struct);

            result = nla.ResultPool(edge_input_struct, net_input_struct, network_atlas, nonpermuted_edge_test_results,...
                nonpermuted_network_test_results, permuted_edge_test_results, ranked_permuted_network_test_results);
            
        end
        
        function ranked_results = collateNetworkPermutationResults(obj, nonpermuted_edge_test_results, network_atlas, nonpermuted_network_test_results,...
            permuted_network_test_results, network_test_options)
            
            

            % Warning: Hacky code. Because of the way non-permuted network tests and permuted are called from the front, they are stored
            % in different objects. (Notice the input argument for non-permuted network results). Eventually, it should probably be done
            % that we do them all here. That may be another ticket. For now, we're copying over.
            for test_index = 1:numNetTests(obj)    
                for test_index2 = 1:numNetTests(obj)
                    if nonpermuted_network_test_results{test_index2}.test_name == permuted_network_test_results{test_index}.test_name
                        permuted_network_test_results{test_index}.no_permutations = nonpermuted_network_test_results{test_index2}.no_permutations;
                        break
                    end
                end
            end
            
            % REMOVE CALL TO COHENS D UNTIL WE DETERMINE CORRECT CALC FOR IT ADE 2025MAR24
            % Run Cohen's D
%             cohen_d_test = nla.net.CohenDTest();
%             for test_index = 1:numNetTests(obj)
%                 
%                 permuted_network_test_results{test_index} = cohen_d_test.run(nonpermuted_edge_test_results, network_atlas,...
%                     permuted_network_test_results{test_index});
%             end

            ranked_results = obj.rankResults(network_test_options, permuted_network_test_results, network_atlas.numNetPairs());
        end

        function [permuted_edge_test_results, permuted_network_test_results] = runPermSeparateEdgeAndNet(obj, input_struct, net_input_struct,...
            network_atlas, num_perms, perm_seed)
            
            %This is code that first runs all edge permutations, and then
            %runs all net permutations
            %NOTE: This currently involves saving all edge results from all
            %permutations in the working results object
            if ~exist('perm_seed', 'var')
                perm_seed = false;
            end

            permuted_edge_test_results = obj.runEdgeTestPerm(input_struct, num_perms, perm_seed);
            permuted_network_test_results = obj.runNetTestsPerm(net_input_struct, network_atlas, permuted_edge_test_results);
        end
        
        function [permuted_edge_results, permuted_network_results] = runEdgeAndNetPerm(obj, edge_input_struct, net_input_struct,...
            net_atlas, edge_result_nonperm, num_perms, perm_seed)
            
            % get current parallel pool or start a new one
            [number_of_processes, blocks] = obj.initializeParallelPool(num_perms);
            
            parfor process = 1:number_of_processes
                network_result_block = obj.runEdgeAndNetPermBlock(edge_input_struct, net_input_struct, net_atlas,...
                    blocks(process), blocks(process+1), perm_seed);
                network_result_blocks{process} = network_result_block;
            end
            
            permuted_edge_results = nla.edge.result.PermBase();
            permuted_edge_results.perm_count = num_perms;
            % and net level result chunks
            permuted_network_results = network_result_blocks{1};
            for process = 2:number_of_processes
                current_network_test_results = network_result_blocks{process};
                for test_index = 1:numNetTests(obj)
                    current_test_network_result = current_network_test_results(test_index);
                    permuted_network_results{test_index}.merge(current_test_network_result);
                end
            end
        end
        
        function network_result_block = runEdgeAndNetPermBlock(obj, edge_input_struct, net_input_struct, net_atlas,...
            block_start, block_end, perm_seed)
        
            for iteration = block_start:block_end - 1
                rng(iteration);
                permuted_input = edge_input_struct.permute_method.permute(edge_input_struct);
                permuted_input.iteration = iteration;
                
                single_edge_result = obj.runEdgeTest(permuted_input);
                network_results = obj.runNetTests(net_input_struct, single_edge_result, net_atlas, true);
                
                % Ugh, this is so horrible. Have to do this due to Matlab not being able to index 2D arrays separately among
                % indexes
                if iteration - block_start + 1 == 1
                    for test = 1:numNetTests(obj)
                        network_result_block{test} = copy(network_results{test});
                    end
                else
                    for test = 1:numNetTests(obj)
                        network_result_block{test}.merge(network_results{test});
                    end
                end

                if ~islogical(obj.data_queue)
                    send(obj.data_queue, iteration);
                end
            end
        end
        
        function edge_result_perm = runEdgeTestPerm(obj, input_struct, num_perms, perm_seed)
            % Optional perm_seed parameter for replicating runs. If not
            % passed in, is set from current date/time and thus will
            % produce different results, assuming you don't run it twice at
            % the same time
            if ~exist('perm_seed', 'var') || islogical(perm_seed)
                rng(posixtime(datetime()));
                perm_seed = randi(intmax('uint32'), 'uint32');
            end
            
            [num_procs, blocks] = obj.initializeParallelPool(num_perms);
            
            edge_result_blocks = cell(1, num_procs);
            for proc = 1:num_procs
                % it may be possible to wrap these up into a reduction w/ custom func(merge)
                % and eliminate the chunk merging step
                edge_result = obj.runEdgeTestPermBlock(input_struct, blocks(proc), blocks(proc+1), perm_seed);
                edge_result_blocks{proc} = edge_result;
            end

            % merge edge level result chunks
            edge_result_perm = edge_result_blocks{1}.copy();
            if num_procs > 1
                edge_result_perm.merge(edge_result_blocks(2:end));
            end
            edge_result_perm.perm_seed = perm_seed;
        end
        
        function edge_result_perm = runEdgeTestPermBlock(obj, input_struct, block_start, block_end, perm_seed)
            % set permutation method
            edge_result_perm = nla.edge.result.PermBase();
            
            for iteration = block_start:block_end - 1
                % set RNG per-iteration based on the random seed and
                % iteration number, so the # of processes doesn't impact
                % the result(important for repeatability if running 
                % permutations with the same seed intentionally)
                rng(bitxor(perm_seed, iteration));
                permuted_input = input_struct.permute_method.permute(input_struct);
                permuted_input.iteration = iteration;
                
                single_edge_result = obj.runEdgeTest(permuted_input);
                edge_result_perm.addSingleEdgeResult(single_edge_result);
                
                if ~islogical(obj.data_queue)
                    send(obj.data_queue, iteration);
                end
            end
        end                
        
        function edge_result = runEdgeTest(obj, input_struct)
            if ~isfield(input_struct, 'iteration')
                input_struct.iteration = 0;
            end
            
            edge_result = obj.edge_test.run(input_struct);
        end

        function net_level_results = runNetTestsPerm(obj, net_input_struct, net_atlas, perm_edge_results)
            num_perms = perm_edge_results.perm_count;
            [num_procs, blocks] = obj.initializeParallelPool(num_perms);
            
            % split permuted edge results into a 'block' for each worker
            allEdgeResBlocks = {};
            for process = 1:num_procs
                thisBlockIdxs = blocks(process):(blocks(process+1)-1);
                allEdgeResBlocks{process} = perm_edge_results.getResultsByIdxs(thisBlockIdxs);
            end
            
            network_result_blocks = {};
            for process = 1:num_procs
                network_results = obj.runNetTestsPermBlock(net_input_struct, net_atlas, allEdgeResBlocks{process}, blocks(process));
                network_result_blocks{process} = network_results;
            end
            
            % and net level result chunks
            net_level_results = {};
            for test_index = 1:numNetTests(obj)
                current_test_network_results = {};
                for process_index = 1:num_procs
                    current_process_network_results = network_result_blocks{process_index};
                    current_test_network_results{process_index} = current_process_network_results{test_index};
                end
                net_level_results{test_index} = copy(current_test_network_results{1});
                net_level_results{test_index}.merge(current_test_network_results(2:end));
            end
        end
        
        function network_results = runNetTestsPermBlock(obj, net_input_struct, net_atlas, perm_edge_results, block_start)
            
            for iteration_within_block = 1:perm_edge_results.perm_count
                previous_edge_result = perm_edge_results.getResultsByIdxs(iteration_within_block);
                net_input_struct.iteration = block_start + iteration_within_block - 1;
                if iteration_within_block == 1
                    network_results = obj.runNetTests(net_input_struct, previous_edge_result, net_atlas, true);
                else
                    next_permutation_network_result = obj.runNetTests(net_input_struct, previous_edge_result, net_atlas, true);
                    for i = 1:numel(obj.net_tests)
                        network_results{i}.concatenateResult(next_permutation_network_result{i});
                    end
                end
                if ~islogical(obj.data_queue)
                    send(obj.data_queue, iteration_within_block);
                end
            end
        end
        
        function net_results = runNetTests(obj, input_struct, edge_result, net_atlas, permutations)
            net_results = {};
            for i = 1:numNetTests(obj)
                net_results{i} = obj.net_tests{i}.run(input_struct, edge_result, net_atlas, permutations);
            end
        end
        
        function val = numNetTests(obj)
            val = numel(obj.net_tests);
        end

        function ranked_results = rankResults(obj, input_options, permuted_network_results, number_of_network_pairs)
            

            ranked_results = permuted_network_results;
            for test = 1:numNetTests(obj)
                ranker = nla.net.ResultRank(permuted_network_results{test}, number_of_network_pairs);
                ranked_results_object = ranker.rank();
                ranked_results{test} = ranked_results_object;
                if any(strcmp(ranked_results{test}.test_name, obj.correlation_input_tests))
                    ranked_results{test}.no_permutations = rmfield(ranked_results{test}.no_permutations, "legacy_two_sample_p_value");
                    ranked_results{test}.no_permutations = rmfield(ranked_results{test}.no_permutations, "uncorrected_two_sample_p_value");
                end
            end
        end
    end
end

