classdef PermBase < handle
    
    properties
        avg_prob_sig = NaN
        perm_count = uint32(0)
        coeff = []
        prob = []
        prob_sig = []
    end
    
    properties (Access = protected)
        
        lastResultIdx = 0;
        
    end
    
    methods
        
        function obj = PermBase()
            
        end
        
        % merge results from a different PermBase object into this one
        function merge(obj, results)
            
            
            for j = 1:numel(results)                
                obj.coeff.v = [obj.coeff.v,results{j}.coeff.v];
                obj.prob.v = [obj.prob.v, results{j}.prob.v];
                obj.prob_sig.v = [obj.prob_sig.v, results{j}.prob_sig.v];
                obj.avg_prob_sig = [obj.avg_prob_sig, results{j}.avg_prob_sig];
                obj.perm_count = obj.perm_count + results{j}.perm_count;
            end
                        
            obj.lastResultIdx = obj.perm_count;
        end
        
        function addSingleEdgeResult(obj, edgeResult)
            
            obj.perm_count = obj.perm_count + 1;
            
            %If this is first result, initialize our trimatrices from that
            %result's size
            if isempty(obj.coeff)
                obj.coeff = nla.TriMatrix(edgeResult.coeff.size, nla.TriMatrixDiag.REMOVE_DIAGONAL);
                obj.prob = nla.TriMatrix(edgeResult.coeff.size, nla.TriMatrixDiag.REMOVE_DIAGONAL);
                obj.prob_sig = nla.TriMatrix(edgeResult.coeff.size, nla.TriMatrixDiag.REMOVE_DIAGONAL);
                obj.avg_prob_sig = [];
            end
            
            idxToAdd = obj.lastResultIdx + 1;
            obj.coeff.v(:,idxToAdd) = edgeResult.coeff.v;
            obj.prob.v(:,idxToAdd) = edgeResult.prob.v;
            obj.prob_sig.v(:,idxToAdd) = edgeResult.prob_sig.v;
            
            obj.avg_prob_sig(idxToAdd) = sum(edgeResult.prob_sig.v) ./ numel(edgeResult.prob_sig.v);
            
            obj.lastResultIdx = obj.lastResultIdx + 1;
            
        end
        
        function preallocForNPermutations(obj, numExpectedPermutations)
            
            currNumResults = size(obj.coeff.v,2);
            
            emptyColsToAdd = numExpectedPermutations - currNumResults;
            elemsPerCol = size(obj.coeff.v,1);
            
            if emptyColsToAdd > 0
                obj.coeff.v = [obj.coeff.v, zeros(elemsPerCol, emptyColsToAdd)];
                obj.prob.v = [obj.prob.v, zeros(elemsPerCol, emptyColsToAdd)];
                obj.prob_sig.v = [obj.prob_sig.v, zeros(elemsPerCol, emptyColsToAdd)];
            end
            
        end
        
        function copyObj = copy(obj)
            
            copyObj = nla.edge.result.PermBase();
            
            copyObj.avg_prob_sig = obj.avg_prob_sig;
            copyObj.perm_count = obj.perm_count;
            copyObj.coeff = copy(obj.coeff);
            copyObj.prob = copy(obj.prob);
            copyObj.prob_sig = copy(obj.prob_sig);
            
        end
        
        function result_subset = getResultsByIdxs(obj, indices)
            result_subset = nla.edge.result.PermBase();
            
            result_subset.avg_prob_sig = obj.avg_prob_sig(indices);
            result_subset.perm_count = length(indices);
            
            %Initialize TriMatrix objects as empty, but proper size
            result_subset.coeff = nla.TriMatrix(obj.coeff.size, nla.TriMatrixDiag.REMOVE_DIAGONAL);
            result_subset.prob = nla.TriMatrix(obj.coeff.size, nla.TriMatrixDiag.REMOVE_DIAGONAL);
            result_subset.prob_sig = nla.TriMatrix(obj.coeff.size, nla.TriMatrixDiag.REMOVE_DIAGONAL);
            
            result_subset.coeff.v = obj.coeff.v(:,indices);
            result_subset.prob.v = obj.prob.v(:,indices);
            result_subset.prob_sig.v = obj.prob_sig.v(:,indices);
            
        end
        
        function output(obj, net_atlas, flags)
            %nla.edge.result.Base wants permuted edge results to
            %support an 'output' function, but currently does nothing.
            %
            %Determine if this function is a placeholder for future
            %functionality, or can be deleted
            
        end
        
    end
    
end