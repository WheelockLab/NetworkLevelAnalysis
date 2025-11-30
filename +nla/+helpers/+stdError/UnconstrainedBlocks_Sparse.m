classdef UnconstrainedBlocks_Sparse < nla.helpers.stdError.UnconstrainedBlocks

    properties
        APPROX_MAX_MEMORY_GB = 20; %Limit how much data this algorithm should have in memory at a time
    end
    
    methods
        
        function stdErr = calculate(obj, sweStdErrInput)
            %Computes Standard Error, but uses assumption that V matrix is
            %sparse to speed up calculation. If V is not sparse, will
            %probably take longer than normal matrix multiplication
            %V matrix will be calculated in blocks, where each block along
            %the diagonal corresponds to a group. Each block will be the
            %residual error of all observations in the group multiplied by
            %the transpose of the error, ie residual * residual';
            %
            %Efficient algo adapted from
            %https://www.mathworks.com/matlabcentral/answers/87629-efficiently-multiplying-diagonal-and-general-matrices
            %(And in case that page goes away, copying text in file
            %/data/wheelock/data1/people/ecka/fastDiagMatrixMultAlgo.txt)
            
            %Wrinkle here is that when off diagonal elements of V can be
            %non-zero, memory considerations must be applied. 
            
            
            %rename variables for readability
            pinvDesignMtx = sweStdErrInput.pinvDesignMtx;
            residual = sweStdErrInput.residual;
            groupIds = sweStdErrInput.scanMetadata.groupId;
            unqGrps = unique(groupIds);
            
            obj.throwErrorIfVEntirelyFull(unqGrps);
            
            
            [numCovariates, ~] = size(pinvDesignMtx);
            [numObs, numFcEdges] = size(residual);
            
            %determine which elements of V will be non-zero based on
            %grouping.
            %First reorganize data so that observations within groups are
            %next to each other
            [pinvDesignMtx_grp, residual_grp, groupIds_grp] = obj.reorderDataByGroup(pinvDesignMtx, residual, groupIds);
            
            
            %Find row and column locations where non-zero values in V will
            %be
            [rowIdxs, colIdxs] = obj.getCoordsOfNonzerosInV(groupIds);
            numNonzeroElems = length(rowIdxs);
            
            %Split data into blocks so that memory used by this algorithm
            %will attempt to be kept below APPROX_MAX_MEMORY_GB
            edgesPerMemBlock = obj.calcNumEdgesPerMemoryBlock(numNonzeroElems, numCovariates, obj.APPROX_MAX_MEMORY_GB);
            
            if edgesPerMemBlock < 1
                error(['%s: Number of nonzero V elements will exceed memory ceiling allocated ',...
                    'to this class (APPROX_MAX_MEMORY_GB property currently set to %i GB'],class(obj), obj.APPROX_MAX_MEMORY_GB)
            end
            
            %Make precomputed matrix that will multiply all 
            invDesMtxSelfMultPreCompute = zeros(numCovariates,numCovariates,numNonzeroElems);

            for i = 1:numNonzeroElems
                invDesMtxSelfMultPreCompute(:,:,i) = pinvDesignMtx_grp(:,colIdxs(i)) * pinvDesignMtx_grp(:,rowIdxs(i))';                
            end
            invDesMtxSelfMultPreCompute = reshape(invDesMtxSelfMultPreCompute,numCovariates^2, numNonzeroElems);
            
            %Use pregenerated matrix to compute covariance of our estimates
            %of the regressors. 
                        
            
            %Precompute which elems of flattened beta covariance matrix
            %correspond to diagonal elements if matrix were square
            diagElemIdxsInFlatArr = 1:(numCovariates+1):numCovariates^2; 
            
            %Compute stdError one memory block at a time
            flatVTheseFcEdges = zeros(numNonzeroElems, edgesPerMemBlock);
            stdErr = zeros(numCovariates, numFcEdges);
            fcEdgeBlockStart = 1;
            
            while fcEdgeBlockStart <= numFcEdges
                fcEdgeBlockEnd = min(fcEdgeBlockStart + edgesPerMemBlock - 1, numFcEdges);
                
                %If this is the last block, it may not have as many fcEdges
                %as the other blocks and therefore won't fill up the
                %preallocated flatVTheseFcEdges matrix.
                %Clear the old one and create a new, smaller one.
                %This is because I have not found a way to efficiently
                %subindex a large matrix in MATLAB. See this MATLAB forum
                %post for the weirdness:
                % https://www.mathworks.com/matlabcentral/answers/54522-why-is-indexing-vectors-matrices-in-matlab-very-inefficient
                %As part of their test, they showed for a large vector a,
                %that "a(1:end) = 1" is 5 times slower than "a(:) = 1"
                %Best actual speed solution is probably to incorporate
                %these algos into a C MEX file. ADE 20220526 
                fcEdgesThisBlock = fcEdgeBlockEnd - fcEdgeBlockStart + 1;                
                if fcEdgesThisBlock < edgesPerMemBlock
                    clear flatVTheseFcEdges
                    flatVTheseFcEdges = zeros(numNonzeroElems, fcEdgesThisBlock);
                end
                                
                
                flatVTheseFcEdges = obj.makeNonZeroFlatV(...
                                        residual_grp(:,fcEdgeBlockStart:fcEdgeBlockEnd),...
                                        groupIds_grp, flatVTheseFcEdges );
                                    
                betaCovarianceFlat = (invDesMtxSelfMultPreCompute * flatVTheseFcEdges);
                
                
                stdErr(:,fcEdgeBlockStart:fcEdgeBlockEnd) = sqrt(betaCovarianceFlat(diagElemIdxsInFlatArr,:));
                
                fcEdgeBlockStart = fcEdgeBlockEnd + 1;
            end

        end
        
    end
    
    methods (Access = private)
        
        
        function [rowIdxs, colIdxs] = getCoordsOfNonzerosInV(obj, groupIdVec)
            %Find the row and column indices that will have non-zero values
            %if we were to build the whole V matrix for correlated blocks
            %based on the groupIds of the elements
            
            numObs = length(groupIdVec);
            vTemplate = zeros(numObs, numObs);
            rowIndexMtx = (1:numObs)' * ones(1,numObs);
            colIndexMtx = ones(numObs,1) * (1:numObs);
            
            unqGrps = unique(groupIdVec);
            countInGrps = histcounts(groupIdVec,[unqGrps;Inf]);
            
            tmpRowIdx = 1;
            for grpIdx = 1:length(unqGrps)
                startIdx = tmpRowIdx;
                endIdx = tmpRowIdx + countInGrps(grpIdx)-1;
                
                vTemplate([startIdx:endIdx],[startIdx:endIdx]) = 1;
                tmpRowIdx = endIdx + 1;            
            end
            
            vTemplateFlat = reshape(vTemplate,numel(vTemplate),1);
            rowMtxFlat = reshape(rowIndexMtx,numel(vTemplate),1);
            colMtxFlat = reshape(colIndexMtx,numel(vTemplate),1);
            
            rowIdxs = rowMtxFlat(vTemplateFlat==1);
            colIdxs = colMtxFlat(vTemplateFlat==1);            
            
        end
        
        function flatV = makeNonZeroFlatV(obj, residual, groupIds, flatV)
            %assumes residuals have already been sorted by groupId
            %computes the nonzero elements of V given correlated errors
            %within groups
            %
            %Accepts a previously allocated block of flatV as input and
            %overwrites values during algo for speed / memory concerns
            %
            %If flatV is larger than needed for residual, write only to the
            %first columns needed
            
            
            unqGrps = unique(groupIds);
            countInGrps = histcounts(groupIds,[unqGrps;Inf]);
            
            [~, numFcEdgesThisBlock] = size(residual);
            [~, numFcEdgesInFlatV] = size(flatV);
            
            if numFcEdgesInFlatV > numFcEdgesThisBlock
                flatV(:,(numFcEdgesThisBlock+1):end) = [];                
            end
            
            rowIdx = 1;
            
            for grpIdx = 1:length(unqGrps)                
                
                thisGrpId = unqGrps(grpIdx);
                numObsThisGrp = countInGrps(grpIdx);
                thisGrpFlag = groupIds == thisGrpId;
                residThisGrp = residual(thisGrpFlag,:);
                                                
                
                for i = 1:numObsThisGrp
                    for j = 1:numObsThisGrp
                        flatVAllEdgesThisRow = residThisGrp(i,:) .* residThisGrp(j,:);
                        flatV(rowIdx,:) = flatVAllEdgesThisRow;
                        rowIdx = rowIdx + 1;
                    end
                end
                
            end
            
        end
        
        function edgesPerMemBlock = calcNumEdgesPerMemoryBlock(obj, numNonzeroElemsInV, numCovariates, memBlockSize_GB)
            
            GBPerMtxElem = 8 / (1024*1024*1024);
            
            memPrecomputedMtx_GB = numNonzeroElemsInV * (numCovariates^2) * GBPerMtxElem;
            memForFcEdgeBlocks_GB = memBlockSize_GB - memPrecomputedMtx_GB;
            
            memPerEdge_GB = numNonzeroElemsInV * GBPerMtxElem;
            
            edgesPerMemBlock = floor(memForFcEdgeBlocks_GB / memPerEdge_GB);
            
        end     
        
    end

end