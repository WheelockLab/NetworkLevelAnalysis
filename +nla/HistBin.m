classdef HistBin
    % Logarithmic histogram bins for probabilities.
    properties (Constant)
        BIN_COUNT = 10000
        EDGE_COUNT = nla.HistBin.BIN_COUNT + 1
        EDGES = [0; logspace(-200, 0, nla.HistBin.BIN_COUNT)']
        SIZE = [nla.HistBin.BIN_COUNT, 1]
        SMALLEST_POS_EDGE = 1e-200
    end
end

