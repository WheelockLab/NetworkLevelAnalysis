classdef BaseCorrTest < nla.net.BaseTest
    methods
        function obj = BaseCorrTest()
            obj@nla.net.BaseTest();
        end
    end
    methods (Static)
        function inputs = requiredInputs()
            % Inputs that must be provided to run the test
            inputs = requiredInputs@nla.net.BaseTest();
            inputs{end + 1} = nla.inputField.Number('d_max', "Net-level Cohen's D threshold >", 0, 0.5, 1);
        end
    end
end

