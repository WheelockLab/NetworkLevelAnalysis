classdef OrdinaryLeastSquares < nla.inputField.SandwichEstimator
    %This class will act nearly identically to the SandwichEstimator input,
    %with the only difference being that it will startup the sandwich
    %estimator input GUI with an extra flag indicating that we will force
    %the standard error calculation to be the homoskedastic one.
    %
    %It overrides the following functions from the base class:
    %draw(...), giving the button a different label specific to OLS, and
    %a different callback that starts the sandwich input GUI with a flag
    %that forces OLS
    
    methods
    
        function obj = OrdinaryLeastSquares()
            obj = obj@nla.inputField.SandwichEstimator();
            obj.name = 'ordinary_least_squares';
            obj.disp_name = 'Ordinary Least Squares';
        end
    end
    
    methods
        function [w, h] = draw(obj, x, y, parent, fig)
            import nla.inputField.LABEL_H nla.inputField.LABEL_GAP
            
            table_h = 300;
            h = LABEL_H + LABEL_GAP + table_h + LABEL_GAP + LABEL_H + LABEL_GAP + LABEL_H;
            h = 50;
            
            
            %% 'Set Behavior' button
            [obj.button_start_sandwich_gui, w3] = obj.createButton(obj.button_start_sandwich_gui, 'OLS Settings', parent, x,...
                y - h + LABEL_H + LABEL_GAP + LABEL_H, @(h,e)obj.button_startSandwichGUI_withForceOLS_Callback());
           
            w = 0;
            
        end
        
    end
    
    methods (Access = protected)
        
        function button_startSandwichGUI_withForceOLS_Callback(obj, ~)

            obj.settingsObj.FORCE_ORDINARY_LEAST_SQUARES = true;

            settingsGUI = nla.edge.SandwichEstimatorInputGUI(obj.settingsObj);
            uiwait(settingsGUI.SandwichEstimatorInputUIFigure);  
            if obj.settingsObj.isValid()
                obj.satisfied = true;
            end

        end
    
    end
    
    
end