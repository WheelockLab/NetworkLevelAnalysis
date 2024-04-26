function [str, valid] = validateInputStruct(inp, str, valid)
    for i = 1:numel(inp)
        if ~inp{i}.satisfied
            valid = false;
            str = [str sprintf('\n - ') inp{i}.disp_name];
        end
    end
end