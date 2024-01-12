classdef BaseCorrTest < nla.net.BaseTest
    methods
        function obj = BaseCorrTest()
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseTest();
        end
    end
    methods (Static)
        function inputs = requiredInputs()
            % Inputs that must be provided to run the test
            import nla.* % required due to matlab package system quirks
            inputs = requiredInputs@nla.net.BaseTest();
            inputs{end + 1} = inputField.Number('d_max', "Net-level Cohen's D threshold >", 0, 0.5, 1);
        end
    end
end

