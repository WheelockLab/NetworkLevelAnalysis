function [str, valid] = validateInputStruct(inp, str, valid)
    import nla.* % required due to matlab package system quirks
    for i = 1:numel(inp)
        if ~inp{i}.satisfied
            valid = false;
            str = [str sprintf('\n - ') inp{i}.disp_name];
        end
    end
end