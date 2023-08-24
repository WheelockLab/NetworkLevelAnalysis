classdef ResultPool
    %RESULTPOOL Pool of results (observed, permuted, edge and net level)
    
    properties
        net_atlas
        input_struct
        net_input_struct
        edge_result
        net_results
        perm_edge_result
        perm_net_results
        version
    end
    
    methods
        function obj = ResultPool(input_struct, net_input_struct, net_atlas, edge_result, net_results, perm_edge_result, perm_net_results)
            import nla.* % required due to matlab package system quirks
            obj.input_struct = input_struct;
            obj.net_input_struct = net_input_struct;
            obj.net_atlas = net_atlas;
            obj.edge_result = edge_result;
            obj.perm_edge_result = perm_edge_result;
            obj.net_results = net_results;
            obj.perm_net_results = perm_net_results;
            obj.version = VERSION;
        end
        
        function output(obj)
            import nla.* % required due to matlab package system quirks
            flags = struct();
            flags.display_sig = obj.containsSigBasedNetworkResult();
            obj.edge_result.output(obj.net_atlas, flags);
            if ~islogical(obj.perm_edge_result)
                obj.perm_edge_result.output(obj.net_atlas, flags);
            end
            flags = struct();
            flags.show_nonpermuted = true;
            flags.show_full_conn = true;
            flags.show_within_net_pair = true;
            %Add to display net results as nla.PlotType.FIGURE (ADE 20221121)
            flags.plot_type = nla.PlotType.FIGURE;
            if ~islogical(obj.net_results)
                for i = 1:numel(obj.net_results)
                    obj.net_results{i}.output(obj.input_struct, obj.net_input_struct, obj.net_atlas, obj.edge_result, flags);
                    obj.perm_net_results{i}.output(obj.input_struct, obj.net_input_struct, obj.net_atlas, obj.edge_result, flags);
                end
            end
        end
        
        function val = containsSigBasedNetworkResult(obj)
            import nla.* % required due to matlab package system quirks
            val = false;
            if ~islogical(obj.perm_net_results)
                for i = 1:size(obj.perm_net_results, 1)
                    if isa(obj.perm_net_results{i}, 'net.BaseSigResult')
                        val = true;
                    end
                end
            end
        end
        
        function to_file(obj, filename)
            import nla.* % required due to matlab package system quirks
            results = obj;
            % also create a struct version of the results for compatibility
            results_as_struct = helpers.classToStructRecursive(obj);
            save(filename, 'results', 'results_as_struct', '-nocompression','-v7.3');
        end
        
        function saveSummaryTable(obj, filename)
            import nla.* % required due to matlab package system quirks

            for n = 1:obj.net_atlas.numNets()
                net_name = obj.net_atlas.nets(n).name;
                for n2 = n:obj.net_atlas.numNets()
                    net2_name = obj.net_atlas.nets(n2).name;
                    net_pairs_mat(n2, n) = string(net_name);
                    net_pairs2_mat(n2, n) = string(net2_name);
                    if n == n2
                        net_pair_size_mat(n2, n) = nla.helpers.triNum(obj.net_atlas.nets(n).numROIs);
                    else
                        net_pair_size_mat(n2, n) = obj.net_atlas.nets(n).numROIs * obj.net_atlas.nets(n2).numROIs;
                    end
                end
            end
            net_pairs = TriMatrix(net_pairs_mat, TriMatrixDiag.KEEP_DIAGONAL);
            net_pairs2 = TriMatrix(net_pairs2_mat, TriMatrixDiag.KEEP_DIAGONAL);
            net_pair_size = TriMatrix(net_pair_size_mat, TriMatrixDiag.KEEP_DIAGONAL);
            summary_table = table(net_pairs.v, net_pairs2.v, net_pair_size.v, 'VariableNames', ["Network 1", "Network 2", "Net-Pair Size"]);
            for i = 1:numel(obj.perm_net_results)
                summary_table = obj.perm_net_results{i}.genSummaryTable(summary_table);
            end

            writetable(summary_table, filename, 'Delimiter', '\t');
        end
    end
    
    methods (Static)
        function obj = from_file(filename)
            import nla.* % required due to matlab package system quirks
            file_struct = load(filename);
            obj = file_struct.results;
        end
    end
end

