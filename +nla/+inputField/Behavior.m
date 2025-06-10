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
        permutation_groups = false
        permutation_group_idx = false
        covariates_enabled
    end
    
    properties (Access = protected)
        label = false
        button = false
        table = false
        button_set_bx = false
        button_add_cov = false
        button_sub_cov = false
        button_view_design_mtx = false
        button_add_permutation_level = false
        button_remove_permutation_level = false
        select_partial_variance_label = false
        select_partial_variance = false
    end
    
    methods
        function obj = Behavior()
            obj.covariates_enabled = nla.inputField.CovariatesEnabled.ALL;
            obj.resetSelectedCol();
        end
        
        function resetSelectedCol(obj)
            obj.behavior_idx = false;
            obj.covariates = false;
            obj.covariates_idx = false;
            obj.cols_selected = false;
        end
        
        function [w, h] = draw(obj, x, y, parent, fig)
            import nla.inputField.LABEL_H nla.inputField.LABEL_GAP

            obj.fig = fig;
            
            table_w = max(parent.Position(3) - (LABEL_GAP * 4), 500);
            table_h = 300;
            
            h = LABEL_H + LABEL_GAP + table_h + LABEL_GAP + LABEL_H + LABEL_GAP + LABEL_H;
            
            %% Create label
            if ~isgraphics(obj.label)
                obj.label = uilabel(parent);
            end
            obj.label.Text = 'Behavior:';
            label_w = nla.inputField.widthOfString(obj.label.Text, LABEL_H);
            obj.label.HorizontalAlignment = 'left';
            obj.label.Position = [x, y - LABEL_H, label_w + LABEL_GAP, LABEL_H];
            
            %% Create button
            if ~isgraphics(obj.button)
                obj.button = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.buttonClickedCallback());
            end
            button_w = 100;
            obj.button.Position = [x + label_w + LABEL_GAP, y - LABEL_H, button_w, LABEL_H];
            
            w = label_w + LABEL_GAP + button_w;
            
            %% Create table
            if ~isgraphics(obj.table)
                obj.table = uitable(parent);
                obj.table.CellSelectionCallback = @obj.cellSelectedCallback;
                obj.table.SelectionType = 'column';
                obj.table.ColumnName = {'None'};
                obj.table.RowName = {};
                obj.table.Position = [x, y - (table_h + LABEL_GAP + LABEL_H), table_w, table_h];
            end
            
            w2 = table_w;
            
            %% 'Set Behavior' button
            [obj.button_set_bx, w3] = obj.createButton(obj.button_set_bx, 'Set Behavior', parent, x,...
                y - h + LABEL_H + LABEL_GAP + LABEL_H, @(h,e)obj.button_set_bxClickedCallback());
            obj.button_set_bx.BackgroundColor = '#E3FDD8';
            
            %% 'Add Covariate' button
            [obj.button_add_cov, w4] = obj.createButton(obj.button_add_cov, 'Add Covariate', parent, x + w3 + LABEL_GAP,...
                y - h + LABEL_H + LABEL_GAP + LABEL_H, @(h,e)obj.button_add_covClickedCallback());
            obj.button_add_cov.BackgroundColor = '#FADADD';
            
            %% 'Remove Covariate' button
            [obj.button_sub_cov, w5] = obj.createButton(obj.button_sub_cov, 'Remove Covariate', parent,...
                x + w3 + LABEL_GAP + w4 + LABEL_GAP, y - h + LABEL_H + LABEL_GAP + LABEL_H,...
                @(h,e)obj.button_sub_covClickedCallback());
            obj.button_sub_cov.BackgroundColor = '#FADADD';
            
            %% 'View Design Matrix' button
            [obj.button_view_design_mtx, w6] = obj.createButton(obj.button_view_design_mtx, 'View Design Matrix', parent,...
                x + w3 + LABEL_GAP + w4 + LABEL_GAP + w5 + LABEL_GAP, y - h + LABEL_H + LABEL_GAP + LABEL_H,...
                @(h,e)obj.button_view_design_mtxClickedCallback());
            
            %% Add Permutation button
            [obj.button_add_permutation_level, permutation_button_width] = obj.createButton(...
                obj.button_add_permutation_level, "Add Permutation Group Level", parent, x, y - h + LABEL_H,...
                @(h,e)obj.addPermutationGroup()...
            );
            obj.button_add_permutation_level.BackgroundColor = "#8CABFB";

            %% Remove Permutation button
            [obj.button_remove_permutation_level, remove_permutation_button_width] = obj.createButton(...
                obj.button_remove_permutation_level, "Remove Last Permutation Group", parent,...
                x + permutation_button_width + LABEL_GAP, y - h + LABEL_H, @(h,e)obj.removePermutationGroup()...
            );
            obj.button_remove_permutation_level.BackgroundColor = "#8CABFB";

            %% 'Partial Variance' options
            obj.select_partial_variance_label = uilabel(parent);
            obj.select_partial_variance_label.HorizontalAlignment = 'left';
            obj.select_partial_variance_label.Text = 'Remove shared variance from covariates:';
            select_partial_variance_label_w = nla.inputField.widthOfString(obj.select_partial_variance_label.Text, LABEL_H);
            obj.select_partial_variance_label.Position = [x, y - h - LABEL_H - LABEL_GAP, select_partial_variance_label_w, LABEL_H];
            
            select_partial_variance_w = 100;
            obj.select_partial_variance = uidropdown(parent);
            obj.genPartialVarianceOpts();
            obj.select_partial_variance.Position = [x + select_partial_variance_label_w + LABEL_GAP, y - h - LABEL_H - LABEL_GAP,...
                select_partial_variance_w, LABEL_H];
            obj.select_partial_variance.Value = nla.PartialVarianceType.NONE;
            w7 = x + select_partial_variance_label_w + LABEL_GAP + select_partial_variance_w;
            
            w = max([w, w2, w3 + LABEL_GAP + w4 + LABEL_GAP + w5 + LABEL_GAP + w6, w7]);
        end
        
        function undraw(obj)
            
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
            if isgraphics(obj.button_add_permutation_level)
                delete(obj.button_add_permutation_level)
            end
            if isgraphics(obj.button_remove_permutation_level)
                delete(obj.button_remove_permutation_level)
            end
        end
        
        function read(obj, input_struct)
            
            obj.loadField(input_struct, 'behavior_filename');
            obj.loadField(input_struct, 'behavior_full');
            obj.loadField(input_struct, 'behavior');
            obj.loadField(input_struct, 'behavior_idx');
            
            if obj.covariates_enabled == nla.inputField.CovariatesEnabled.NONE
                obj.covariates = false;
                obj.covariates_idx = false;
            else
                obj.loadField(input_struct, 'covariates');
                obj.loadField(input_struct, 'covariates_idx');
            end
            
            if isfield(input_struct, 'partial_variance')
                if obj.covariates_enabled == nla.inputField.CovariatesEnabled.ALL
                    obj.select_partial_variance.Value = input_struct.partial_variance;
                elseif obj.covariates_enabled == nla.inputField.CovariatesEnabled.ONLY_FC
                    if input_struct.partial_variance == nla.PartialVarianceType.NONE
                        obj.select_partial_variance.Value = nla.PartialVarianceType.NONE;
                    else
                        obj.select_partial_variance.Value = nla.PartialVarianceType.ONLY_FC;
                    end
                end
            else
                obj.select_partial_variance.Value = nla.PartialVarianceType.NONE;
            end
            
            obj.update();
        end
        
        function [input_struct, error] = store(obj, input_struct)
            
            input_struct.behavior_filename = obj.behavior_filename;
            input_struct.behavior_full = obj.behavior_full;
            input_struct.behavior = obj.behavior;
            input_struct.behavior_idx = obj.behavior_idx;
            input_struct.covariates = obj.covariates;
            input_struct.covariates_idx = obj.covariates_idx;
            input_struct.partial_variance = obj.select_partial_variance.Value;
            input_struct.permutation_groups = obj.permutation_groups;
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
        
        function buttonClickedCallback(obj, ~)
            
            if ismac
                [file, path, idx] = uigetfile('*.*', 'Select Behavior File');
            else
                [file, path, idx] = uigetfile( ...
                    {'*.txt;*.dat;*.csv', 'Text (*.txt,*.dat,*.csv)'; ...
                    '*.xls;*.xlsb;*.xlsm;*.xlsx;*.xltm;*.xltx;*.ods', 'Spreadsheet (*.xls,*.xlsb,*.xlsm,*.xlsx,*.xltm,*.xltx,*.ods)'; ...
                    '*.xml', 'XML (*.xml)'; ...
                    '*.docx', 'Word (*.docx)'; ...
                    '*.mat', 'MATLAB table (*.mat)'; ...
                    '*.html;*.xhtml;*.htm', 'HTML (*.html,*.xhtml,*.htm)'}, 'Select Behavior File');
            end
            if idx ~= 0
                try
                    prog = uiprogressdlg(obj.fig, 'Title', 'Loading behavior file', 'Message', sprintf('Loading %s', file),...
                        'Indeterminate', true);
                    drawnow;

                    if idx == 5
                        containing_struct = load([path file]);
                        fn = fieldnames(containing_struct);
                        if numel(fn) == 1
                            fname = fn{1};
                            if istable(containing_struct.(fname))
                                behavior_file = containing_struct.(fname);
                            else
                                error('No table to load from MATLAB file.');
                            end
                        else
                            error('Could not find table to load from MATLAB file - make sure it only contains a table.');
                        end
                    else
                        behavior_file = readtable([path file]);
                    end
                    obj.behavior_full = behavior_file;
                    obj.behavior_filename = file;

                    % reset selected since we loaded a new behavior_full
                    obj.resetSelectedCol();

                    close(prog);
                    % check for unusual values in behavior
                    labels = obj.behavior_full.Properties.VariableNames;
                    could_not_load_some_columns = false;
                    could_not_load_str = [];
                    
                    non_numerical_indexes = [];
                    for i=1:numel(obj.behavior_full.Properties.VariableNames)
                        col = table2array(obj.behavior_full(:, i));
                        if ~(isnumeric(col) || islogical(col))
                            non_numerical_indexes = [non_numerical_indexes i];
                        end
                    end
                    if numel(non_numerical_indexes) > 0
                        could_not_load_some_columns = true;
                        could_not_load_str = [could_not_load_str sprintf("Columns %s could not be loaded due to containing non-numerical values.",...
                            nla.helpers.humanReadableList(labels(non_numerical_indexes)))];
                        obj.behavior_full(:, non_numerical_indexes) = [];
                    end
                    
                    vals = table2array(obj.behavior_full);

                    containsNaN = sum(isnan(vals)) > 0;
                    repeatedNines = ((vals == 99) + (vals == 999) + (vals == 9999)) > 0;
                    unusualValues = abs((vals - mean(vals)) ./ std(vals)) > 3;
                    containsRepeatedNines = sum(repeatedNines & unusualValues) > 0;
                    if sum(containsNaN) > 0
                        could_not_load_some_columns = true;
                        could_not_load_str = [could_not_load_str sprintf("Columns %s could not be loaded due to containing NaN values.",...
                            nla.helpers.humanReadableList(labels(containsNaN)))];
                        colindexes = [1:numel(labels)];
                        obj.behavior_full(:, colindexes(containsNaN)) = [];
                    end
                    
                    if could_not_load_some_columns
                        uialert(obj.fig, join(could_not_load_str, newline), 'Warning', 'Icon', 'warning');
                    end
                    
                    if sum(containsRepeatedNines) > 0
                        uialert(obj.fig, sprintf("Columns %s contain unusual values of repeating 9's (99, 9999, etc).\nIf you are using these to mark missing values for subjects, you should either avoid using the offending columns, or remove the offending subjects from your behavioral file and functional connectivity before loading them in.",...
                            nla.helpers.humanReadableList(labels(containsRepeatedNines))), 'Warning', 'Icon', 'warning');
                    end

                    obj.update();
                catch ex
                    close(prog);
                    uialert(obj.fig, ex.message, 'Error while loading behavior file');
                end
            end
        end
        
        function genPartialVarianceOpts(obj)
            import nla.PartialVarianceType

            if obj.covariates_enabled == nla.inputField.CovariatesEnabled.ALL
                obj.select_partial_variance.Items = {'None', 'FC + BX', 'Only BX', 'Only FC'};
                obj.select_partial_variance.ItemsData = [PartialVarianceType.NONE, PartialVarianceType.FCBX, PartialVarianceType.ONLY_BX, PartialVarianceType.ONLY_FC];
            elseif obj.covariates_enabled == nla.inputField.CovariatesEnabled.ONLY_FC
                obj.select_partial_variance.Items = {'None', 'Only FC'};
                obj.select_partial_variance.ItemsData = [PartialVarianceType.NONE, PartialVarianceType.ONLY_FC];
            else
                obj.select_partial_variance.Items = {'None'};
                obj.select_partial_variance.ItemsData = [PartialVarianceType.NONE];
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
            
            if ~islogical(obj.covariates_idx)
                labels = {obj.table.ColumnName{obj.covariates_idx}};
                nla.gfx.drawDesignMtx(obj.covariates, labels);
            end
        end
        
        function addPermutationGroup(obj, ~)
            if islogical(obj.permutation_group_idx)
                obj.permutation_group_idx = [];
            end
            if islogical(obj.permutation_groups)
                obj.permutation_groups = [];
            end
            if obj.cols_selected
                obj.permutation_group_idx = union(obj.permutation_group_idx, obj.cols_selected);
                obj.permutation_groups = table2array(obj.table.Data(:, obj.permutation_group_idx));
            end
            if isempty(obj.permutation_group_idx)
                obj.permutation_group_idx = false;
                obj.permutation_groups = false;
            end
            obj.update();
        end

        function removePermutationGroup(obj, ~)
            if islogical(obj.permutation_group_idx)
                obj.permutation_group_idx = [];
            end
            if islogical(obj.permutation_groups)
                obj.permutation_groups = [];
            end
            if obj.cols_selected
                obj.permutation_group_idx = setdiff(obj.permutation_group_idx, obj.cols_selected);
                obj.permutation_groups = table2array(obj.table.Data(:, obj.permutation_group_idx));
            end
            if isempty(obj.permutation_group_idx)
                obj.permutation_group_idx = false;
                obj.permutation_groups = false;
            end
            obj.update();
        end

        function update(obj)
            import nla.inputField.widthOfString nla.inputField.LABEL_H
                    
            if islogical(obj.behavior_filename)
                obj.button.Text = 'Select';
            else
                obj.button.Text = obj.behavior_filename;
            end
            obj.button.Position(3) = widthOfString(obj.button.Text, LABEL_H) + widthOfString('  ', LABEL_H + nla.inputField.LABEL_GAP);
            
            removeStyle(obj.table);
            if islogical(obj.behavior_full)
                
                obj.table.Enable = 'off';
                obj.button_set_bx.Enable = false;
                
                obj.button_add_cov.Enable = false;
                obj.button_sub_cov.Enable = false;
                obj.button_view_design_mtx.Enable = false;
                obj.select_partial_variance.Enable = false;
                obj.select_partial_variance_label.Enable = false;
                obj.button_add_permutation_level.Enable = false;
                obj.button_remove_permutation_level.Enable = false;
            else
                obj.table.Data = obj.behavior_full;
                obj.table.ColumnName = obj.behavior_full.Properties.VariableNames;
                
                % Set column colors
                obj.satisfied = false;
                if ~islogical(obj.behavior_idx)
                    bx_s = uistyle('BackgroundColor','#E3FDD8');
                    addStyle(obj.table, bx_s, 'column', obj.behavior_idx)
                    obj.satisfied = true;
                end
                
                if ~islogical(obj.covariates_idx)
                    cov_s = uistyle('BackgroundColor','#FADADD');
                    addStyle(obj.table, cov_s, 'column', obj.covariates_idx)
                end
                
                if ~islogical(obj.permutation_group_idx)
                    permutation_groups_style = uistyle("BackgroundColor", "#8CABFB");
                    addStyle(obj.table, permutation_groups_style, "column", obj.permutation_group_idx);
                end

                % Enable buttons
                obj.table.Enable = 'on';
                obj.button_set_bx.Enable = true;
                obj.button_add_permutation_level.Enable = true;
                obj.button_remove_permutation_level.Enable = true;

                enable_cov = (obj.covariates_enabled ~= nla.inputField.CovariatesEnabled.NONE);
                obj.button_add_cov.Enable = enable_cov;
                obj.button_sub_cov.Enable = enable_cov;
                obj.button_view_design_mtx.Enable = enable_cov;

                
                obj.genPartialVarianceOpts();
                
                obj.select_partial_variance.Enable = ~islogical(obj.covariates_idx);
                obj.select_partial_variance_label.Enable = ~islogical(obj.covariates_idx);
                if islogical(obj.covariates_idx)
                    obj.select_partial_variance.Value = false;
                end
            end
        end
    end
end

