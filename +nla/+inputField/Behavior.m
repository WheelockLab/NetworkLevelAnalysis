classdef Behavior < nla.inputField.InputField
    properties (Constant)
        name = 'behavior';
        disp_name = 'Behavior';
    end
    
    properties
        behavior_filename = false
        behavior_full = false
        behavior = false
        behavior_idx = false
        covariates = false
        covariates_idx = false
        cols_selected = false
        covariates_enabled = true
    end
    
    properties (Access = protected)
        label = false
        button = false
        table = false
        button_set_bx = false
        button_add_cov = false
        button_sub_cov = false
        button_view_design_mtx = false
        select_partial_variance_label = false
        select_partial_variance = false
    end
    
    methods
        function obj = Behavior()
            import nla.* % required due to matlab package system quirks
        end
        
        function [w, h] = draw(obj, x, y, parent, fig)
            import nla.* % required due to matlab package system quirks
            
            obj.fig = fig;
            
            table_w = 510;
            table_h = 300;
            
            label_gap = inputField.LABEL_GAP;
            h = inputField.LABEL_H + label_gap + table_h + label_gap + inputField.LABEL_H + label_gap + inputField.LABEL_H;
            
            %% Create label
            if ~isgraphics(obj.label)
                obj.label = uilabel(parent);
            end
            obj.label.Text = 'Behavior:';
            label_w = inputField.widthOfString(obj.label.Text, inputField.LABEL_H);
            obj.label.HorizontalAlignment = 'left';
            obj.label.Position = [x, y - inputField.LABEL_H, label_w + label_gap, inputField.LABEL_H];
            
            %% Create button
            if ~isgraphics(obj.button)
                obj.button = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.buttonClickedCallback());
            end
            button_w = 100;
            obj.button.Position = [x + label_w + label_gap, y - inputField.LABEL_H, button_w, inputField.LABEL_H];
            
            w = label_w + label_gap + button_w;
            
            %% Create table
            if ~isgraphics(obj.table)
                obj.table = uitable(parent);
                obj.table.CellSelectionCallback = @obj.cellSelectedCallback;
                obj.table.SelectionType = 'column';
                obj.table.ColumnName = {'None'};
                obj.table.RowName = {};
                obj.table.Position = [x, y - (table_h + label_gap + inputField.LABEL_H), table_w, table_h];
            end
            
            w2 = table_w;
            
            %% 'Set Behavior' button
            [obj.button_set_bx, w3] = obj.createButton(obj.button_set_bx, 'Set Behavior', parent, x, y - h + inputField.LABEL_H + label_gap + inputField.LABEL_H, @(h,e)obj.button_set_bxClickedCallback());
            obj.button_set_bx.BackgroundColor = '#E3FDD8';
            
            %% 'Add Covariate' button
            [obj.button_add_cov, w4] = obj.createButton(obj.button_add_cov, 'Add Covariate', parent, x + w3 + label_gap, y - h + inputField.LABEL_H + label_gap + inputField.LABEL_H, @(h,e)obj.button_add_covClickedCallback());
            obj.button_add_cov.BackgroundColor = '#FADADD';
            
            %% 'Remove Covariate' button
            [obj.button_sub_cov, w5] = obj.createButton(obj.button_sub_cov, 'Remove Covariate', parent, x + w3 + label_gap + w4 + label_gap, y - h + inputField.LABEL_H + label_gap + inputField.LABEL_H, @(h,e)obj.button_sub_covClickedCallback());
            obj.button_sub_cov.BackgroundColor = '#FADADD';
            
            %% 'View Design Matrix' button
            [obj.button_view_design_mtx, w6] = obj.createButton(obj.button_view_design_mtx, 'View Design Matrix', parent, x + w3 + label_gap + w4 + label_gap + w5 + label_gap, y - h + inputField.LABEL_H + label_gap + inputField.LABEL_H, @(h,e)obj.button_view_design_mtxClickedCallback());
            
            %% 'Partial Variance' options
            obj.select_partial_variance_label = uilabel(parent);
            obj.select_partial_variance_label.HorizontalAlignment = 'left';
            obj.select_partial_variance_label.Text = 'Remove shared variance from covariates:';
            select_partial_variance_label_w = inputField.widthOfString(obj.select_partial_variance_label.Text, inputField.LABEL_H);
            obj.select_partial_variance_label.Position = [x, y - h, select_partial_variance_label_w, inputField.LABEL_H];
            
            select_partial_variance_w = 100;
            obj.select_partial_variance = uidropdown(parent);
            obj.select_partial_variance.Items = {'None', 'FC + BX', 'Only BX', 'Only FC'};
            obj.select_partial_variance.ItemsData = [PartialVarianceType.NONE, PartialVarianceType.FCBX, PartialVarianceType.ONLY_BX, PartialVarianceType.ONLY_FC];
            obj.select_partial_variance.Position = [x + select_partial_variance_label_w + label_gap, y - h, select_partial_variance_w, inputField.LABEL_H];
            obj.select_partial_variance.Value = 0;
            w7 = x + select_partial_variance_label_w + label_gap + select_partial_variance_w;
            
            w = max([w, w2, w3 + label_gap + w4 + label_gap + w5 + label_gap + w6, w7]);
        end
        
        function undraw(obj)
            import nla.* % required due to matlab package system quirks
            if isgraphics(obj.button)
                delete(obj.button)
            end
            if isgraphics(obj.label)
                delete(obj.label)
            end
            if isgraphics(obj.table)
                delete(obj.table)
            end
            if isgraphics(obj.button_set_bx)
                delete(obj.button_set_bx)
            end
            if isgraphics(obj.button_add_cov)
                delete(obj.button_add_cov)
            end
            if isgraphics(obj.button_sub_cov)
                delete(obj.button_sub_cov)
            end
            if isgraphics(obj.button_view_design_mtx)
                delete(obj.button_view_design_mtx)
            end
            if isgraphics(obj.select_partial_variance_label)
                delete(obj.select_partial_variance_label)
            end
            if isgraphics(obj.select_partial_variance)
                delete(obj.select_partial_variance)
            end
        end
        
        function read(obj, input_struct)
            import nla.* % required due to matlab package system quirks
            obj.loadField(input_struct, 'behavior_filename');
            obj.loadField(input_struct, 'behavior_full');
            obj.loadField(input_struct, 'behavior');
            obj.loadField(input_struct, 'behavior_idx');
            
            if obj.covariates_enabled
                obj.loadField(input_struct, 'covariates');
                obj.loadField(input_struct, 'covariates_idx');
            else
                obj.covariates = false;
                obj.covariates_idx = false;
            end
            
            if isfield(input_struct, 'partial_variance') && obj.covariates_enabled
                obj.select_partial_variance.Value = input_struct.partial_variance;
            else
                obj.select_partial_variance.Value = false;
            end
            
            obj.update();
        end
        
        function input_struct = store(obj, input_struct)
            import nla.* % required due to matlab package system quirks
            input_struct.behavior_filename = obj.behavior_filename;
            input_struct.behavior_full = obj.behavior_full;
            input_struct.behavior = obj.behavior;
            input_struct.behavior_idx = obj.behavior_idx;
            input_struct.covariates = obj.covariates;
            input_struct.covariates_idx = obj.covariates_idx;
            input_struct.partial_variance = obj.select_partial_variance.Value;
        end
    end
    
    methods (Access = protected)
        function [button, w] = createButton(obj, button, label, parent, x, y, callback)
            import nla.* % required due to matlab package system quirks
            
            %% Create button
            if ~isgraphics(button)
                button = uibutton(parent, 'push', 'ButtonPushedFcn', callback);
            end
            button_w = 100;
            button.Position = [x, y - inputField.LABEL_H, button_w, inputField.LABEL_H];
            
            button.Text = label;
            button.Position(3) = inputField.widthOfString(button.Text, inputField.LABEL_H) + inputField.widthOfString('  ', inputField.LABEL_H + inputField.LABEL_GAP);
            
            w = button.Position(3);
        end
        
        function buttonClickedCallback(obj, ~)
            import nla.* % required due to matlab package system quirks
            [file, path, idx] = uigetfile({'*.txt', 'Behavior (*.txt)'}, 'Select Behavior File'); %TODO add all file options readtable can read from
            
            if idx ~= 0
                % Load file to net_atlas, depending on the filetype. Right now
                % it only supports .mat network atlases but if another file
                % type were added, it would be handled under idx == 2 and so on
                if idx == 1
                    try
                        prog = uiprogressdlg(obj.fig, 'Title', 'Loading behavior file', 'Message', sprintf('Loading %s', file), 'Indeterminate', true);
                        drawnow;
            
                        behavior_file = readtable([path file]);
                        obj.behavior_full = behavior_file; % TODO this should be turned into a table or something before setting the obj property - its a struct now
                        obj.behavior_filename = file;
                        
                        % zero these since we loaded a new behavior_full
                        obj.behavior = false;
                        obj.covariates = false;
                        
                        close(prog);
                        % check for unusual values in behavior
                        vals = table2array(obj.behavior_full);
                        labels = obj.behavior_full.Properties.VariableNames;
                        containsNaN = sum(isnan(vals)) > 0;
                        repeatedNines = ((vals == 99) + (vals == 999) + (vals == 9999)) > 0;
                        unusualValues = abs((vals - mean(vals)) ./ std(vals)) > 3;
                        containsRepeatedNines = sum(repeatedNines & unusualValues) > 0;
                        if sum(containsNaN) > 0
                            uialert(obj.fig, sprintf('Columns %s could not be loaded due to containing NaN values.', nla.helpers.humanReadableList(labels(containsNaN))), 'Warning');
                            colindexes = [1:numel(labels)];
                            obj.behavior_full(:, colindexes(containsNaN)) = [];
                        end
                        if sum(containsRepeatedNines) > 0
                            uialert(obj.fig, sprintf("Columns %s contain unusual values of repeating 9's (99, 9999, etc).\nIf you are using these to mark missing values for subjects, you should either avoid using the offending columns, or remove the offending subjects from your behavioral file and functional connectivity before loading them in.", nla.helpers.humanReadableList(labels(containsRepeatedNines))), 'Warning', 'Icon', 'warning');
                        end
                        
                        obj.update();
                    catch ex
                        close(prog);
                        uialert(obj.fig, ex.message, 'Error while loading behavior file');
                    end
                end
            end
        end
        
        function cellSelectedCallback(obj, src, event)
            obj.cols_selected = unique(event.Indices(:, 2));
        end
        
        function button_set_bxClickedCallback(obj, ~)
            if obj.cols_selected
                obj.behavior_idx = obj.cols_selected(1);
                obj.behavior = table2array(obj.table.Data(:, obj.behavior_idx));
            end
            obj.update();
        end
        
        function button_add_covClickedCallback(obj, ~)
            if islogical(obj.covariates_idx)
                obj.covariates_idx = [];
            end
            if obj.cols_selected
                obj.covariates_idx = union(obj.covariates_idx, obj.cols_selected);
                obj.covariates = table2array(obj.table.Data(:, obj.covariates_idx));
            end
            if isempty(obj.covariates_idx)
                obj.covariates_idx = false;
            end
            obj.update();
        end

        function button_sub_covClickedCallback(obj, ~)
            if islogical(obj.covariates_idx)
                obj.covariates_idx = [];
            end
            if obj.cols_selected
                obj.covariates_idx = setdiff(obj.covariates_idx, obj.cols_selected);
                obj.covariates = table2array(obj.table.Data(:, obj.covariates_idx));
            end
            if isempty(obj.covariates_idx)
                obj.covariates_idx = false;
            end
            obj.update();
        end
        
        function button_view_design_mtxClickedCallback(obj)
            import nla.* % required due to matlab package system quirks
            if ~islogical(obj.covariates_idx)
                labels = {obj.table.ColumnName{obj.covariates_idx}};
                gfx.drawDesignMtx(obj.covariates, labels);
            end
        end
        
        function update(obj)
            import nla.* % required due to matlab package system quirks
                    
            if islogical(obj.behavior_filename)
                obj.button.Text = 'Select';
            else
                obj.button.Text = obj.behavior_filename;
            end
            obj.button.Position(3) = inputField.widthOfString(obj.button.Text, inputField.LABEL_H) + inputField.widthOfString('  ', inputField.LABEL_H + inputField.LABEL_GAP);
            
            removeStyle(obj.table);
            if islogical(obj.behavior_full)
                %obj.table.Visible = false;
                
                obj.table.Enable = 'off';
                obj.button_set_bx.Enable = false;
                
                obj.button_add_cov.Enable = false;
                obj.button_sub_cov.Enable = false;
                obj.button_view_design_mtx.Enable = false;
                obj.select_partial_variance.Enable = false;
                obj.select_partial_variance_label.Enable = false;
            else
                %obj.table.Visible = true;
                % TODO implement this to make the table display behavior_full
                obj.table.Data = obj.behavior_full;
                obj.table.ColumnName = obj.behavior_full.Properties.VariableNames;
                
                % Set column colors
                obj.satisfied = false;
                if ~islogical(obj.behavior_idx)
                    % TODO make this color the label instead of renaming
                    bx_s = uistyle('BackgroundColor','#E3FDD8');
                    addStyle(obj.table, bx_s, 'column', obj.behavior_idx)
                    %obj.table.ColumnName{obj.behavior_idx} = ['[Bx] ' obj.table.ColumnName{obj.behavior_idx}];
                    obj.satisfied = true;
                end
                
                if ~islogical(obj.covariates_idx)
                    % TODO make this color the label instead of renaming
                    cov_s = uistyle('BackgroundColor','#FADADD');
                    addStyle(obj.table, cov_s, 'column', obj.covariates_idx)
%                     for i = 1:numel(obj.covariates_idx)
%                         idx = obj.covariates_idx(i);
%                         obj.table.ColumnName{idx} = ['[Cov] ' obj.table.ColumnName{idx}];
%                     end
                end
                
                % Enable buttons
                obj.table.Enable = 'on';
                obj.button_set_bx.Enable = true;
                
                obj.button_add_cov.Enable = obj.covariates_enabled;
                obj.button_sub_cov.Enable = obj.covariates_enabled;
                obj.button_view_design_mtx.Enable = obj.covariates_enabled;
                
                obj.select_partial_variance.Enable = ~islogical(obj.covariates_idx);
                obj.select_partial_variance_label.Enable = ~islogical(obj.covariates_idx);
                if islogical(obj.covariates_idx)
                    obj.select_partial_variance.Value = 0;
                end
            end
        end
    end
end

