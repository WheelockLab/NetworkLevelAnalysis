classdef DeepCopyable < handle
    methods
        function new = copy(obj)
            %COPY Deep copy of an object
            objByteArray = getByteStreamFromArray(obj);
            new = getArrayFromByteStream(objByteArray);
        end
    end
end

