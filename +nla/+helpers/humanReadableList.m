function str = humanReadableList(list)
    %HUMANREADABLELIST Print a cell-array of strings in a human-readable list format
    n = numel(list);
    if n == 1
        str_cell = list(1);
    elseif n == 2
        str_cell = join(list, ' and ');
    else
        str_cell = join([join(list(1:n - 1), ', '), list(n)], ', and ');
    end
    str = str_cell{1};
end

