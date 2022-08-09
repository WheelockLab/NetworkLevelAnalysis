function inputs = reduce(inputs_unreduced)
    %REDUCE Reduce duplicate inputs
    i = 2;
    while i <= numel(inputs_unreduced)
        duplicate = false;
        for j = 1:i-1
            % if it's equal, it's a duplicate
            if strcmp(class(inputs_unreduced{i}), class(inputs_unreduced{j})) && strcmp(inputs_unreduced{i}.name, inputs_unreduced{j}.name)
                duplicate = true;
                break;
            end
        end
        
        if duplicate
            inputs_unreduced(i) = [];
        else
            i = i + 1;
        end
    end
    inputs = inputs_unreduced;
end

