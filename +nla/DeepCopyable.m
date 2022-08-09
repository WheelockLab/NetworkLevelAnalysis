classdef DeepCopyable < handle
    methods
        function new = copy(obj)
            import nla.* % required due to matlab package system quirks
            %COPY Deep copy of an object
            objByteArray = getByteStreamFromArray(obj);
            new = getArrayFromByteStream(objByteArray);
        end
    end
end

