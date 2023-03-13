classdef BaseTest < nla.Test
    %BASETEST Base class of tests performing net-level analysis
    % The intended behavior of the run function of a net-level test is that
    % it creates a new result object on the nonpermuted run and accepts
    % said result as previous_result on all subsequent permuted runs,
    % modifying it.
    
    methods
        function obj = BaseTest()
            import nla.* % required due to matlab package system quirks
        end 
    end
    
    methods (Abstract)
        run(obj, input_struct, edge_result, net_atlas, previous_result)
    end
    
    methods (Static)
        function inputs = requiredInputs()
            import nla.* % required due to matlab package system quirks
            inputs = {inputField.Integer('behavior_count', 'Test count:', 1, 1, Inf), inputField.Number('prob_max', 'Net-level P threshold <', 0, 0.05, 1)};
        end
    end
end
