function saveErrorObjInTimestampedMatfile(saveFolder, errorObj)        
    
    nowTime = datetime;
    nowTime.Format = 'yyyyMMdd-hhmmss';
    
    errFilename = sprintf('error_%s.mat',nowTime);
    errFullFilename = fullfile(saveFolder, errFilename);
    
    save(errFullFilename, 'errorObj');

end