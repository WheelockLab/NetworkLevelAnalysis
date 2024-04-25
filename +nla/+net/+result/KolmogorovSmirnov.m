classdef KolmogorovSmirnov < nla.net.BaseCorrResult
    %KOLMOGOROVSMIRNOV The output result of a KolmogorovSmirnovTest
    
    properties (Constant)
        name = "Kolmogorov-Smirnov"
        name_formatted = "KS"
    end
    
    properties
        ks
        ss_ks
    end
    
    methods
        function obj = KolmogorovSmirnov(size)
            % Superclass constructor
            obj@nla.net.BaseCorrResult(size);

            obj.ks = nla.TriMatrix(size, nla.TriMatrixDiag.KEEP_DIAGONAL);
        end

        function prob = withinNetPairOneNet(obj, coeff_net, coeff_net_perm)
            [~, prob, ~] = kstest2(coeff_net, coeff_net_perm);
        end

        function table_new = genSummaryTable(obj, table_old)
            table_new = [genSummaryTable@nla.net.BasePermResult(obj, table_old), table(obj.ks.v, 'VariableNames', [obj.name])];
        end
    end
end
