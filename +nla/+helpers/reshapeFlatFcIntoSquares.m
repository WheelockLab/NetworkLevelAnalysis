function squareFc = reshapeFlatFcIntoSquares(flatFc)
    [numSubj, numFcEdges] = size(flatFc);
    fcEdgeSize = (1 + sqrt(1 + 8*numFcEdges)) / 2;
    
    if mod(fcEdgeSize,1) ~= 0
        error(['\nFirst dimension of input flat FC is not consistent with size of a square fc.\n',...
                ' %i unique edges results in flat FC square size of %1.2f\n'],numFcEdges, fcEdgeSize)
    elseif numFcEdges < numSubj
        warning(['Input flat FC has more edges than subjects (%i edges, %i subjects). ',...
                'Make sure you don''t need to transpose your input fc'],numFcEdges, numSubj);
    end
    fcTriMtx = nla.TriMatrix(fcEdgeSize);
    
    fcTriMtx.v = flatFc';
    squareFc = fcTriMtx.asMatrix();
    
    for i = 1:numSubj
        squareFc(:,:,i) = fullSquareFromLowerTriangleAndNans(squareFc(:,:,i));
    end
end

function outSquare = fullSquareFromLowerTriangleAndNans(inSquare)
    inSquareNoNans = inSquare;
    inSquareNoNans(isnan(inSquare)) = 0;
    
    %Make upper diag match lower diag
    outSquare = inSquareNoNans + inSquareNoNans';

end