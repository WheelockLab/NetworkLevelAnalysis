classdef SwEStdErrorInput
    
    properties
        
        scanMetadata nlaEckDev.swedata.ScanMetadata
        residual % [numObservations x numOutputVectors]
        pinvDesignMtx % pseudoinverse of design matrix [numCovariates x numObservations]        
        
    end
    
end