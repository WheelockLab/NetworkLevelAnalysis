classdef Guillaume < nla.helpers.stdError.AbstractSwEStdErrStrategy
    
    %some code here is adapted from Guillaume implementation of Sandwich
    %Estimator available at http://www.nisox.org/Software/SwE/
    %(specifically, swe_cp.m, or swe_contrasts.m where noted)
    %adapted blocks of code are marked with a comment noting where
    %in the original source file they were referenced from
            
    properties
        totalSpectralCorrections;
    end
    
    methods
        
        function stdError = calculate(obj, sweStdErrInput)
            
            
                  
            [numCovariates, numObservations] = size(sweStdErrInput.pinvDesignMtx);
            [~, numBetaVectors] = size(sweStdErrInput.residual);
            
            betaCovar = nla.TriMatrix(zeros(numCovariates,numCovariates,numBetaVectors), nla.TriMatrixDiag.KEEP_DIAGONAL);
            obj.totalSpectralCorrections = 0;  
            
            grpIdUnq = unique(sweStdErrInput.scanMetadata.groupId);           
                                    
            
            for grpIdx = 1:length(grpIdUnq)
                
                %Filter data to just the scans that fall in this group           
                thisGrpId = grpIdUnq(grpIdx);                
                scansInGrp = sweStdErrInput.scanMetadata.groupId == thisGrpId;
                

                scanMetadataThisGrp = nlaEckDev.swedata.ScanMetadata(sweStdErrInput.scanMetadata);
                scanMetadataThisGrp.filterByGroupId(thisGrpId);
                
                pinvDesignMtxThisGrp = sweStdErrInput.pinvDesignMtx(:,scansInGrp);
                residThisGrp = sweStdErrInput.residual(scansInGrp,:);
                
                %If this group does not span multiple visits, need
                %temporary special behavior since TriMatrix objects cannot
                %represent 1x1 matrices
                unqVisThisGrp = unique(scanMetadataThisGrp.visitId);
                
                if length(unqVisThisGrp) == 1
                    betaCovarThisGroup = obj.calcCovarOnlyOneVisit(residThisGrp, pinvDesignMtxThisGrp);                    
                else
                    %If there are multiple visits in this group, calculate
                    %using Guillaume algo from NiSox tutorial

                    visitCovarThisGroup = obj.calcVisitCovarMtx(scanMetadataThisGrp, residThisGrp);                    
                    betaCovarThisGroup = obj.calcDesignMtxCovarOneGroup(scanMetadataThisGrp, visitCovarThisGroup, pinvDesignMtxThisGrp);
                    
                end                
                
                betaCovar.v = betaCovar.v + betaCovarThisGroup.v;
                
            end
            
            stdError = sqrt(betaCovar.v(betaCovar.getDiagElemIdxs,:));
        
        
        end
    
    end
    
    methods (Access = private)
        
        function betaCovariance = calcCovarOnlyOneVisit(obj, residual, pInvX)
            
            baseVar = mean(residual.^2,1);
            
            %ADAPT lines 377-391
            numCovariates = size(pInvX,1);
            numBetaCovarElems = numCovariates * (numCovariates + 1) / 2;    
                        
            weights = zeros(numBetaCovarElems, 1);
            
            betaElemIdx = 0;
            for betaRowIdx = 1:numCovariates
                for betaColIdx = betaRowIdx:numCovariates
                    betaElemIdx = betaElemIdx + 1;
                    
                    thisWeightElem = pInvX(betaRowIdx, :) * pInvX(betaColIdx, :)';

                    weights(betaElemIdx, 1) = thisWeightElem;
                    
                end
            end
            
            numFcEdges = size(residual,2);
            betaCovariance = nla.TriMatrix(zeros(numCovariates, numCovariates, numFcEdges), nla.TriMatrixDiag.KEEP_DIAGONAL);
            betaCovariance.v = weights * baseVar;
            
            
        end
        
        function visitCovariance = calcVisitCovarMtx(obj, scanMetadata, residual)
            
            
            [numScans, numFcEdges] = size(residual);
            unqVis = unique(scanMetadata.visitId);
            numUnqVis = length(unqVis);
            
            %Initialize covariance object to hold results
            initZeroData = zeros(numUnqVis,numUnqVis,numFcEdges);
            visitCovariance = nla.TriMatrix(initZeroData, nla.TriMatrixDiag.KEEP_DIAGONAL);
            %visitCovariance = swedata.ManyFlatCovarianceMtx(numUnqVis, numFcEdges);           

            %First calculate diag elems of visit covar mtx
            visitCovariance = obj.calcDiagCovarElems(visitCovariance, scanMetadata, residual);

            %Here Guillaume (2014) would remove pixels that show zero
            %variance from residual, beta, and covariance matrices. We have
            %decided instead to retain all data

            %calculate off diag elems of visit covar mtx
            visitCovariance = obj.calcOffDiagCovarElems(visitCovariance, scanMetadata, residual);

            %NaN may be produced in cov. estimation when one
            %corresponding variance is 0 (Per Guillaume). Set NaN's to 0.
            visitCovariance.v(isnan(visitCovariance.v)) = 0;

            %Find if any eigenvalues of the covariance matrices for each
            %voxel are < 0. If they are, set them to 0 and regenerate the
            %covariance matrix for that voxel (Per Guillaume)
            allCovLowerDiagMtx = visitCovariance.asMatrix();
            allCovLowerDiagMtx(isnan(allCovLowerDiagMtx))=0;
            
            
            for fcIdx = 1:numFcEdges
                thisLowerDiagMtx = allCovLowerDiagMtx(:,:,fcIdx);
                thisCovMtx = thisLowerDiagMtx + thisLowerDiagMtx' - diag(diag(thisLowerDiagMtx));
                
                
                [V, D] = eig(thisCovMtx);
                if any(diag(D)<0)
                    D(D<0) = 0;
                    thisCovMtx = V * D * V';
                    visitCovariance.v(:,fcIdx) = thisCovMtx(tril(ones(size(thisCovMtx)))==1);
                    obj.totalSpectralCorrections = obj.totalSpectralCorrections + 1;
                end
            end
            
            
        end
        
        function covar = calcDiagCovarElems(obj, covar, scanMetadata, residual)
            
            %ADAPT swe_cp.m lines 740-743
                        
            unqVisits = unique(scanMetadata.visitId);
            
            for elemIdx = covar.getDiagElemIdxs()
                
                [thisVisRowInCovarMtx, ~] = covar.getRowAndColOfElem(elemIdx);
                thisVisId = unqVisits(thisVisRowInCovarMtx);
                scanFlagThisVis = scanMetadata.visitId == thisVisId;
                
                covar.v(elemIdx, :) = mean(residual(scanFlagThisVis,:).^2,1);

            end
        end
        
        
        
        function covar = calcOffDiagCovarElems(obj, covar, scanMetadata, residual)
            
            %ADAPT lines 755-762            
            
            for elemIdx = covar.getOffDiagElemIdxs()

                [visId1,visId2] = covar.getRowAndColOfElem(elemIdx);

                [flagVis1, flagVis2] = obj.getFlagsOfSubjScansWithPairOfVisits(scanMetadata, visId1, visId2);

                if any(flagVis1)
                    covar.v(elemIdx,:) = ...
                        sum(residual(flagVis1,:).*residual(flagVis2,:)).* ...
                        sqrt(...
                            mean(residual(flagVis1,:).^2,1) .* mean(residual(flagVis2,:).^2,1) ./ ...
                            ( sum(residual(flagVis1,:).^2,1) .* sum(residual(flagVis2,:).^2,1) )...
                        );
                end

            end
        end
        
        
        
        function [flagVis1, flagVis2] = getFlagsOfSubjScansWithPairOfVisits(obj, scanMetadata, visId1, visId2)
            %Finds scans corresponding to subjects that have data for both of a pair of
            %visit IDs in a given group. 
            %For the pair of visits, returns indices of scans that fall in
            %visId1 and visId2 in the given group
            %Inputs: 
            % scanIdInfo - instance of swedata.ScanIdInfo. This class contains subjId, groupId, and visitId;
            % grpId - groupId to filter on
            % visId1, visId2 - pair of visit id's to search for
            %
            %Outputs:
            % flagVis1 - logical array of whether a scan is vis1 and has
            % a corresponding scan from the same subj and group for visId2
            % flagVis2 - same idea for vis2
                        
            flagVis1 = false(size(scanMetadata.visitId));
            flagVis2 = false(size(scanMetadata.visitId));
            unqSubjs = unique(scanMetadata.subjId);
            
            %NOTE: yes, the transpose of unqSubjs below is needed. 
            %To loop over elements of a vector one by one, MATLAB requires
            %it to be a row vector. Turns out if instead a column vector is
            %used, the loop will run just once using the whole vector.
            for subj = unqSubjs'
                
                hasVisitPair = ...
                    (scanMetadata.subjId == subj) & ...
                    ( (scanMetadata.visitId == visId1) | (scanMetadata.visitId == visId2) );
                
                if any(hasVisitPair)
                    hasVisitPairAndIsVis1 = hasVisitPair & (scanMetadata.visitId == visId1);
                    hasVisitPairAndIsVis2 = hasVisitPair & (scanMetadata.visitId == visId2);
                    flagVis1(hasVisitPairAndIsVis1) = true;
                    flagVis2(hasVisitPairAndIsVis2) = true;
                end
                
            end
                
        end    
        
        
        function betaCovariance = calcDesignMtxCovarOneGroup(obj, scanMetadata, visitCovar, pinvX)                        
                        
            %ADAPT line 797
            weights = obj.calcWeightsForVisitCovarToDesignMtxCovarTform(scanMetadata, visitCovar, pinvX);  
            
            %Initialize empty TriMatrix of proper size, then calculate data field
            numCovariates = size(pinvX,1);
            numFcEdges = size(visitCovar.v,2);
            betaCovariance = nla.TriMatrix(zeros(numCovariates, numCovariates, numFcEdges), nla.TriMatrixDiag.KEEP_DIAGONAL);
            betaCovariance.v = weights * visitCovar.v;
            
            
        end
        
        
        function weights = calcWeightsForVisitCovarToDesignMtxCovarTform(obj, scanMetadata, visitCovar, pInvX)
                                    
            %ADAPT lines 377-391
            numCovariates = size(pInvX,1);
            numBetaCovarElems = numCovariates * (numCovariates + 1) / 2;    
            
            numVisCovarElems = size(visitCovar.v,1);
            
            weights = zeros(numBetaCovarElems, numVisCovarElems);
            
            unqVisits = unique(scanMetadata.visitId);
            
            betaElemIdx = 0;
            for betaRowIdx = 1:numCovariates
                for betaColIdx = betaRowIdx:numCovariates
                    betaElemIdx = betaElemIdx + 1;
                    
                    for visitCovarElem = 1:numVisCovarElems
                        [visitRow, visitCol] = visitCovar.getRowAndColOfElem(visitCovarElem);
                            if any(visitCovarElem == visitCovar.getDiagElemIdxs())
                                matchingVisitIdxs = scanMetadata.visitId == unqVisits(visitRow);
                                thisWeightElem = pInvX(betaRowIdx, matchingVisitIdxs) * pInvX(betaColIdx, matchingVisitIdxs)';
                                
                                weights(betaElemIdx, visitCovarElem) = thisWeightElem;
                                    
                            else
                                visitRowId = unqVisits(visitRow);
                                visitColId = unqVisits(visitCol);
                                
                                [flagRowVis, flagColVis] = obj.getFlagsOfSubjScansWithPairOfVisits(scanMetadata, visitRowId, visitColId);
                                
                                thisWeightElem = pInvX(betaRowIdx, flagRowVis) * pInvX(betaColIdx, flagColVis)' + ...
                                    pInvX(betaRowIdx, flagColVis) * pInvX(betaColIdx, flagRowVis)';
                                
                                weights(betaElemIdx, visitCovarElem) = thisWeightElem;
                                    
                            end                                
                    
                    end
                    
                end
            end
            
        end
        
    end

end