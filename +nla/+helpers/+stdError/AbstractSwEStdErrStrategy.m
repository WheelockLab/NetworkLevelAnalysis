classdef (Abstract) AbstractSwEStdErrStrategy < handle
    
    methods
        
        stdError = calculate(obj, SwEStdErrInput) %input is SwEStdErrorInput object, output is 2D matrix (numCovariates x numFcEdges)
        
    end
    
end
        