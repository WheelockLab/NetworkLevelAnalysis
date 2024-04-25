classdef ChiSquared < nla.net.BaseSigResult
    %CHISQUARED The output result of a Chi-squared test
    
    properties (Constant)
        name = "Chi-Squared"
        name_formatted = "\chi^2"
    end
    
    properties
        chi2
    end
    
    methods
        function obj = ChiSquared(size)
            % Superclass constructor
            obj@nla.net.BaseSigResult(size);
            
            obj.chi2 = nla.TriMatrix(size, nla.TriMatrixDiag.KEEP_DIAGONAL);
        end
        
        function merge(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results)
            merge@nla.net.BaseResult(obj, input_struct, edge_result_nonperm, edge_result, net_atlas, results);
        end
        
        function table_new = genSummaryTable(obj, table_old)
            table_new = [genSummaryTable@nla.net.BasePermResult(obj, table_old), table(obj.chi2.v, 'VariableNames', [obj.name])];
        end
    end
end
