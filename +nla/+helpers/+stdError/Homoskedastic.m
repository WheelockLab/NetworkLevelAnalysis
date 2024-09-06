classdef Homoskedastic < nla.helpers.stdError.AbstractSwEStdErrStrategy

    methods
        
        function stdErr = calculate(obj, sweStdErrInput)
            
            %Calculation of standard error assuming homoskedasticity
            %(errors are independent and identically distributed iid)
            %This is solution of standard error for Ordinary Least Squares
            
            pinvDesignMtx = sweStdErrInput.pinvDesignMtx;
            residual = sweStdErrInput.residual;
            
            
            degOfFree = size(pinvDesignMtx,2) - size(pinvDesignMtx,1) - 1;            
            meanSqErr = sum(residual.^2) ./ degOfFree; %In regression, divide by dof instead of number of data points (per wikipedia)
            
            
            stdErr = sqrt(diag(pinvDesignMtx * pinvDesignMtx')*meanSqErr);            
            

        end
        
    end

end