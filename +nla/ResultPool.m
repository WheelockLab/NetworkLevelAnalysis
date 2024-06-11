classdef ResultPool
    %RESULTPOOL Summary of this class goes here
    %   TODO Detailed explanation goes here
    
    properties
        network_atlas
        test_options
        network_test_options
        edge_test_results
        network_test_results
        permutation_edge_test_results
        permutation_network_test_results
        version
    end
    
    methods
        function obj = ResultPool(test_options, network_test_options, network_atlas, edge_test_results,...
                network_test_results, permutation_edge_test_results, permutation_network_test_results)
            if nargin == 0
                return
            end
            obj.test_options = test_options;
            obj.network_test_options = network_test_options;
            obj.network_atlas = network_atlas;
            obj.edge_test_results = edge_test_results;
            obj.permutation_edge_test_results = permutation_edge_test_results;
            obj.network_test_results = network_test_results;
            obj.permutation_network_test_results = permutation_network_test_results;
            obj.commit = nla.helpers.git.commitString(true);
            obj.commit_short = nla.helpers.git.commitString();
            obj.version = nla.VERSION;
        end
        
        function output(obj)
            flags = struct();
            obj.edge_test_results.output(obj.network_atlas, flags);
            if ~islogical(obj.permutation_edge_test_results)
                obj.permutation_edge_test_results.output(obj.network_atlas, flags);
            end
            flags = struct();
            flags.show_nonpermuted = true;
            flags.show_full_conn = true;
            flags.show_within_net_pair = true;
            %Add to display net results as nla.PlotType.FIGURE (ADE 20221121)
            flags.plot_type = nla.PlotType.FIGURE;
            if ~islogical(obj.permutation_network_test_results)
                for i = 1:numel(obj.permutation_network_test_results)
                    obj.permutation_network_test_results{i}.output(obj.network_test_options, obj.network_atlas,...
                        obj.edge_test_results, flags);
                    obj.permutation_network_test_results{i}.output(obj.network_test_options,...
                        obj.network_atlas, obj.edge_test_results, flags);
                end
            end
        end
        
        function value = containsSignifiganceBasedNetworkResult(obj)
            if ~islogical(obj.permutation_network_test_results)
                for i = 1:size(obj.permutation_network_test_results, 1)
                    value = obj.permutation_network_test_results{i}.is_noncorrelation_input;
                end
            end
        end
        
        function to_file(obj, filename)
            results = obj;
            % also create a struct version of the results for compatibility
            results_as_struct = nla.helpers.classToStructRecursive(obj);
            save(filename, 'results', 'results_as_struct', '-nocompression','-v7.3');
        end
        
        function saveSummaryTable(obj, filename)
            import nla.TriMatrix nla.TriMatrixDiag

            for network = 1:obj.network_atlas.numNets()
                network_name = obj.network_atlas.nets(network).name;
                for network2 = network:obj.network_atlas.numNets()
                    network2_name = obj.network_atlas.nets(network2).name;
                    network_pairs_matrix(network2, network) = string(network_name);
                    network_pairs2_matrix(network2, network) = string(network2_name);
                end
            end
            network_pairs = TriMatrix(network_pairs_matrix, TriMatrixDiag.KEEP_DIAGONAL);
            network_pairs2 = TriMatrix(network_pairs2_matrix, TriMatrixDiag.KEEP_DIAGONAL);
            summary_table = table(network_pairs.v, network_pairs2.v, 'VariableNames', ["Network 1", "Network 2"]);
            for i = 1:numel(obj.permutation_network_test_results)
                summary_table = obj.permutation_network_test_results{i}.generateSummaryTable(summary_table);
            end

            writetable(summary_table, filename, 'Delimiter', '\t');
        end
    end
    
    methods (Static)
        function obj = from_file(filename)
            file_struct = load(filename);
            obj = file_struct.results;
        end
    end
end

