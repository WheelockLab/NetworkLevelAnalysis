classdef BaseSigTest < nla.net.BaseTest
    methods
        function obj = BaseSigTest()
            import nla.* % required due to matlab package system quirks
            obj@nla.net.BaseTest();
        end
    end
end

