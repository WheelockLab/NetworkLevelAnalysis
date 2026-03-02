classdef SandwichEstimator < nla.inputField.InputField
    properties
        name = 'sandwich_estimator';
        disp_name = 'Sandwich Estimator';
    end
    
    properties
        settingsObj
    end
    
    properties (Access = protected)
        button_start_sandwich_gui = false        
    end
    
    
    methods
        function obj = SandwichEstimator()
            obj.settingsObj = nla.edge.inputHelpers.SandwichEstimatorInput();
        end
        
        function [w, h] = draw(obj, x, y, parent, fig)
            import nla.inputField.LABEL_H nla.inputField.LABEL_GAP
            
            table_h = 300;
            h = LABEL_H + LABEL_GAP + table_h + LABEL_GAP + LABEL_H + LABEL_GAP + LABEL_H;
            h = 50;
            
            
            %% 'Set Behavior' button
            [obj.button_start_sandwich_gui, w3] = obj.createButton(obj.button_start_sandwich_gui, 'SWE Settings', parent, x,...
                y - h + LABEL_H + LABEL_GAP + LABEL_H, @(h,e)obj.button_startSandwichGUICallback());
           
            w = 0;
            
        end
        
        function undraw(obj)
            
            if isgraphics(obj.button_start_sandwich_gui)
                delete(obj.button_start_sandwich_gui)
            end
        end
        
        function read(obj, input_struct)
            obj.settingsObj = nla.edge.inputHelpers.SandwichEstimatorInput();
            
            obj.settingsObj.loadFieldsFromStruct(input_struct);
            
            
        end
        
        function [input_struct, error] = store(obj, input_struct)
            
            input_struct = obj.settingsObj.pushFieldsIntoStruct(input_struct);
            error = false;
        end
    end
    
    methods (Access = protected)
        function [button, w] = createButton(obj, button, label, parent, x, y, callback)
            
            %% Create button
            if ~isgraphics(button)
                button = uibutton(parent, 'push', 'ButtonPushedFcn', callback);
            end
            button_w = 100;
            button.Position = [x, y - nla.inputField.LABEL_H, button_w, nla.inputField.LABEL_H];
            
            button.Text = label;
            button.Position(3) = nla.inputField.widthOfString(button.Text, nla.inputField.LABEL_H) +...
                nla.inputField.widthOfString('  ', nla.inputField.LABEL_H + nla.inputField.LABEL_GAP);
            
            w = button.Position(3);
        end
        
        
        function button_startSandwichGUICallback(obj, ~)
                        
            obj.settingsObj.FORCE_ORDINARY_LEAST_SQUARES = false;
            settingsGUI = nla.edge.SandwichEstimatorInputGUI(obj.settingsObj);
            uiwait(settingsGUI.SandwichEstimatorInputUIFigure);  
            if obj.settingsObj.isValid()
                obj.satisfied = true;
            end
            
        end
        
        function update(obj)
        end
        
        function settingsStruct = getSettingsObjAsStruct(obj)
            warning off;
            settingsStruct = struct(obj.settingsObj);
            warning on;
            
        end
    end
end

