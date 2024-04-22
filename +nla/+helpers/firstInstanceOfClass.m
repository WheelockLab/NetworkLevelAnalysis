function handle = firstInstanceOfClass(arr, class_name)
%FIRSTINSTANCEOFCLASS find the first instance of a class in a cell vector
    handle = false;
    for i = 1:size(arr, 2)
        if strcmp(class(arr{i}), class_name)
            handle = arr{i};
            return
        end
    end
end
