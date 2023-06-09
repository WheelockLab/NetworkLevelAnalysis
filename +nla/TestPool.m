classdef TestPool < nla.DeepCopyable
    %TESTPOOL Pool of edge and net tests to be run
    
    properties
        edge_test = false
        net_tests = {}
        data_queue = false
    end
    
    methods
        
        function obj = TestPool()
            import nla.* % required due to matlab package system quirks
            % this MUST be instantiated here it cannot be done in the
            % properties field because NLA cannot be imported when setting
            % things in the properties field, hence, NLA specific values
            % cannot be assigned unless you want it to break if they use
            % this toolbox anywhere outside of the NetworkLevelAnalysis
            % folder.
            obj.edge_test = nla.edge.test.Pearson();
        end
        
        function result = runPerm(obj, input_struct, net_input_struct, net_atlas, edge_result_nonperm, net_results_nonperm, num_perms, perm_seed)
            
            % Optional perm_seed parameter for replicating runs. If not
            % passed in, is set from current date/time and thus will
            % produce different results, assuming you don't run it twice at
            % the same time
            if ~exist('perm_seed', 'var')
                rng(posixtime(datetime()));
                perm_seed = randi(intmax('uint32'), 'uint32');
            end
            
                        
            edge_level_result = obj.runPermutedEdgeTest(input_struct, num_perms, perm_seed);
            
            net_level_results = obj.runNetTestsOnPermutedEdgeResults(...
                                        net_input_struct, net_atlas, net_results_nonperm, edge_level_result, edge_result_nonperm);
            
            
            result = nla.ResultPool(input_struct, net_input_struct, net_atlas, edge_result_nonperm, net_results_nonperm, edge_level_result, net_level_results, perm_seed);
            
        end
        
        
        function permEdgeResults = runPermutedEdgeTest(obj, input_struct, num_perms, perm_seed)
            
            % get current parallel pool or start a new one
            p = gcp;
            num_procs = p.NumWorkers;
            
            % blocks of iteration to be handled by each process
            if num_perms < num_procs
                blocks = 1:(num_perms+1);
                num_procs = num_perms;
            else
                blocks = uint32(linspace(1, num_perms + 1, num_procs + 1));
            end
            
            allEdgeResProcBlocks = cell(1, num_procs);
            parfor proc = 1:num_procs
                
                % it may be possible to wrap these up into a reduction w/ custom func(merge)
                % and eliminate the chunk merging step
                thisProcEdgeResults = obj.runEdgePermSingleProc(input_struct, blocks(proc), blocks(proc+1), perm_seed);
                allEdgeResProcBlocks{proc} = thisProcEdgeResults;
                
            end

            % merge edge level result chunks
            permEdgeResults = allEdgeResProcBlocks{1}.copy();
            if num_procs > 1
                permEdgeResults.merge(allEdgeResProcBlocks(2:end));
            end
            
        end
        
        function net_level_results = runNetTestsOnPermutedEdgeResults(obj, net_input_struct, net_atlas, net_results_nonperm, perm_edge_results, edge_result_nonperm)
            % get current parallel pool or start a new one
            p = gcp;
            num_procs = p.NumWorkers;
            
            num_perms = perm_edge_results.perm_count;
            
            % blocks of iteration to be handled by each process
            if num_perms < num_procs
                blocks = 1:(num_perms+1);
                num_procs = num_perms;
            else
                blocks = uint32(linspace(1, double(num_perms + 1), num_procs + 1));
            end
            
            %split permuted edge results into blocks for each worker to
            %process
            allEdgeResBlocks = cell(num_procs, 1);
            for proc = 1:num_procs
                thisBlockIdxs = blocks(proc):(blocks(proc+1)-1);
                allEdgeResBlocks{proc} = perm_edge_results.getResultsByIdxs(thisBlockIdxs);
            end
            
            parfor proc = 1:num_procs
                net_result_block = cell(numNetTests(obj), 1);
                for i = 1:numNetTests(obj)
                    net_result_block{i} = copy(net_results_nonperm{i});
                end
                obj.runNetTestsOnPermEdgeProcBlock(net_input_struct, net_atlas, net_result_block, allEdgeResBlocks{proc}, blocks(proc), blocks(proc+1));
                net_result_blocks{proc} = net_result_block;
            end
            
            % and net level result chunks
            net_level_results = {};
            for test_index = 1:numNetTests(obj)
                for proc_index = 1:num_procs
                    cur_proc_net_results = net_result_blocks{proc_index};
                    cur_test_net_results(proc_index) = cur_proc_net_results(test_index);
                end
                net_level_results{test_index} = cur_test_net_results{1};
                net_level_results{test_index}.merge(net_input_struct, edge_result_nonperm, perm_edge_results, net_atlas, {cur_test_net_results{2:end}});
            end
            
            
        end
        
        function edgePermRes = runEdgePermSingleProc(obj, input_struct, block_start, block_end, perm_seed)
                        
            edgePermRes = nla.edge.result.PermBase();
            
            for iteration = block_start:block_end - 1
                % set RNG per-iteration based on the random seed and
                % iteration number, so the # of processes doesn't impact
                % the result(important for repeatability if running
                % permutations with the same seed intentionally)
                rng(bitxor(perm_seed, iteration));
                permuted_input = input_struct.permute_method.permute(input_struct);
                permuted_input.iteration = iteration;
                thisEdgeRes = obj.runEdgeTest(permuted_input);
                edgePermRes.addSingleEdgeResult(thisEdgeRes);
                
                if ~islogical(obj.data_queue)
                    send(obj.data_queue, iteration);
                end
            end
        end
        
        function previous_net_results = runNetTestsOnPermEdgeProcBlock(obj, net_input_struct, net_atlas, previous_net_results, perm_edge_results, block_start, block_end)
            
            for iteration_within_block = 1:perm_edge_results.perm_count
                previous_edge_result = perm_edge_results.getResultsByIdxs(iteration_within_block);
                net_input_struct.iteration = block_start + iteration_within_block - 1;
                obj.runNetTests(net_input_struct, previous_edge_result, net_atlas, previous_net_results);
                if ~islogical(obj.data_queue)
                    send(obj.data_queue, iteration_within_block);
                end
            end
            
        end
                
        
        function edge_result = runEdgeTest(obj, input_struct)
            if ~isfield(input_struct, 'iteration')
                input_struct.iteration = 0;
            end
            
            edge_result = obj.edge_test.run(input_struct);
        end
        
        function net_results = runNetTests(obj, input_struct, edge_result, net_atlas, previous_results)
            net_results = {};
            for i = 1:numNetTests(obj)
                % Use the corresponding previous test result, if they are
                % all provided, else just pass on the parameter
                previous_result = previous_results;
                if iscell(previous_results)
                    previous_result = previous_results{i};
                end
                net_results{i} = obj.net_tests{i}.run(input_struct, edge_result, net_atlas, previous_result);
            end
        end

        
        
        function val = numNetTests(obj)
            val = numel(obj.net_tests);
        end
        
        function val = containsSigBasedNetworkTest(obj)
            val = false;
            for i = 1:obj.numNetTests()
                if isa(obj.net_tests{i}, 'net.BaseSigTest')
                    val = true;
                end
            end
        end
    end
end

