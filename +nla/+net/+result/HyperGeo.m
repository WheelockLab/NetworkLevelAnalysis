classdef HyperGeo < nla.net.BaseSigResult
    %HYPERGEO The output result of a Hyper-geometric test
    
    properties (Constant)
        name = "Hypergeometric"
        name_formatted = "Hypergeometric"
    end
    
    methods
        function obj = HyperGeo(size)
            % Superclass constructor
            obj@nla.net.BaseSigResult(size);
        end
        
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            merge@nla.net.BaseResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
        end
        
        function table_new = genSummaryTable(obj, table_old)
            table_new = genSummaryTable@nla.net.BasePermResult(obj, table_old);
        end
    end
end
