classdef NLA_GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        NetworkLevelAnalysisUIFigure  matlab.ui.Figure
        FileMenu                      matlab.ui.container.Menu
        OpenpreviousresultMenu        matlab.ui.container.Menu
        GridLayout                    matlab.ui.container.GridLayout
        Panel_3                       matlab.ui.container.Panel
        NoneButton                    matlab.ui.control.Button
        NetTestSelector               matlab.ui.control.ListBox
        NetworkleveltestsCtrlclickformultipleLabel  matlab.ui.control.Label
        BranchLabel                   matlab.ui.control.Label
        EdgeInputsPanel               matlab.ui.container.Panel
        NetInputsPanel                matlab.ui.container.Panel
        Panel                         matlab.ui.container.Panel
        EdgeTestSelector              matlab.ui.control.DropDown
        EdgeleveltestDropDownLabel    matlab.ui.control.Label
        Panel_2                       matlab.ui.container.Panel
        RunButton                     matlab.ui.control.Button
        MethodsPanel                  matlab.ui.container.Panel
        NonPermutedCheckBox           matlab.ui.control.CheckBox
        FullConnCheckBox              matlab.ui.control.CheckBox
        WithinNetPairCheckBox         matlab.ui.control.CheckBox
        RunQualityControlButton       matlab.ui.control.Button
        PermutationcountLabel         matlab.ui.control.Label
        PermutationcountEditField     matlab.ui.control.NumericEditField
    end

    
    properties (Access = private)
        test_pool = nla.TestPool();
        input_struct = struct();
        input_fields = {};
        net_input_struct
        net_input_fields = {};
        stored_edge_result = false;
    end
    
    methods (Access = private)
        function results = runWithInputs(app, mode)
            import nla.*
            % check if all input fields are satisfied
            [error_str, satisfied] = validateInputStruct(app.input_fields, 'Must satisfy fields:', true);
            [error_str, satisfied] = validateInputStruct(app.net_input_fields, error_str, satisfied);
            
            if satisfied
                error_str = "";
                errors_found = false;
                
                % store input fields
                for i = 1:numel(app.input_fields)
                    [app.input_struct, error] = app.input_fields{i}.store(app.input_struct);
                    if ~islogical(error)
                        error_str = [error_str sprintf('\n - %s: %s', app.input_fields{i}.disp_name, error)];
                        errors_found = true;
                    end
                end
                % store input fields
                for i = 1:numel(app.net_input_fields)
                    [app.net_input_struct, error] = app.net_input_fields{i}.store(app.net_input_struct);
                    if ~islogical(error)
                        error_str = [error_str sprintf('\n - %s: %s', app.net_input_fields{i}.disp_name, error)];
                        errors_found = true;
                    end
                end
                
                if errors_found
                    uialert(app.NetworkLevelAnalysisUIFigure, error_str, 'Error with inputs');
                else
                    % Handle partial variance
                    if isfield(app.input_struct, 'partial_variance') && app.input_struct.partial_variance ~= PartialVarianceType.NONE && isfield(app.input_struct, 'covariates') && isfield(app.input_struct, 'func_conn') && isfield(app.input_struct, 'behavior')
                        app.input_struct.func_conn_unpartialed = app.input_struct.func_conn;
                        app.input_struct.behavior_unpartialed = app.input_struct.behavior;
                        [app.input_struct.func_conn, app.input_struct.behavior] = partialVariance(app.input_struct.func_conn, app.input_struct.behavior, app.input_struct.covariates, app.input_struct.partial_variance);
                    end
                    
                    % make sure to deep copy all handles, as memory is shared
                    % between windows
                    if mode == 0
                        NLAResult(copy(app.test_pool), app.input_struct, app.net_input_struct);
                    else
                        NLAQualityControl(copy(app.test_pool), app.input_struct, app.net_input_struct);
                    end
                end
            else
                % TODO ideally the run button would just stay greyed out until
                % all inputs were satisfied
                uialert(app.NetworkLevelAnalysisUIFigure, error_str, 'Inputs not satisfied');
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            import nla.* % required due to matlab package system quirks
            
            app.net_input_struct = net.genBaseInputs();
            app.net_input_struct.perm_count = 10000;
            app.input_struct.perm_count = 10000;
            
            root_path = findRootPath();
            
            app.NetworkLevelAnalysisUIFigure.Name = 'NLA';
            app.NetworkLevelAnalysisUIFigure.Icon = [root_path 'thumb.png'];
            
            app.BranchLabel.Text = sprintf('gui | %s', helpers.git.commitString());
            
            drawnow;
            
            % Edge-level tests
            edgeLevelOptions = genTests('edge.test');
            
            edgeLevelNames = string;
            for i = 1:numel(edgeLevelOptions)
                edgeLevelNames(i) = edgeLevelOptions{i}.name;
            end
            app.EdgeTestSelector.Items = edgeLevelNames;
            app.EdgeTestSelector.ItemsData = edgeLevelOptions;
            
            app.EdgeTestSelectorValueChanged(true);
            
            % Network-level tests
            netLevelOptions = genTests('net.test');
            netLevelNames = string;
            for i = 1:numel(netLevelOptions)
                netLevelNames(i) = netLevelOptions{i}.display_name;
            end
            app.NetTestSelector.Items = netLevelNames;
            app.NetTestSelector.ItemsData = netLevelOptions;
            
            app.NetTestSelectorValueChanged(true);
            
            app.EdgeInputsPanel.AutoResizeChildren = 'off';
        end

        % Value changed function: EdgeTestSelector
        function EdgeTestSelectorValueChanged(app, event)
            import nla.* % required due to matlab package system quirks
            
            test = app.EdgeTestSelector.Value;
            
            app.test_pool.edge_test = test;
            
            app.EdgeInputsPanel.Title = strcat(test.name, ' inputs');
            
            % store old input fields and undraw
            for i = 1:numel(app.input_fields)
                app.input_struct = app.input_fields{i}.store(app.input_struct);
                app.input_fields{i}.undraw();
            end
            
            % required inputs to run this test
            inputs = test.requiredInputs();
            app.input_fields = inputField.reduce(inputs);
            
            % display input fields
            x = inputField.LABEL_GAP * 2;
            y = app.EdgeInputsPanel.InnerPosition(4);
            for i = 1:numel(app.input_fields)
                y = y - inputField.LABEL_GAP;
                [w, h] = app.input_fields{i}.draw(x, y, app.EdgeInputsPanel, app.NetworkLevelAnalysisUIFigure);
                app.input_fields{i}.read(app.input_struct);
                y = y - h;
            end
        end

        % Value changed function: NetTestSelector
        function NetTestSelectorValueChanged(app, event)
            import nla.*
            
            tests = app.NetTestSelector.Value;
            
            app.test_pool.net_tests = tests;
            
            % store old input fields and undraw
            for i = 1:numel(app.net_input_fields)
                app.net_input_struct = app.net_input_fields{i}.store(app.net_input_struct);
                app.net_input_fields{i}.undraw();
            end
            
            % required inputs to run these tests
            inputs = {};
            for i = 1:numel(tests)
                inputs = cat(2, inputs, tests{i}.requiredInputs());
            end
            app.net_input_fields = inputField.reduce(inputs);
            
            % display input fields
            x = inputField.LABEL_GAP * 2;
            y = app.NetInputsPanel.InnerPosition(4);
            for i = 1:numel(app.net_input_fields)
                y = y - inputField.LABEL_GAP;
                [w, h] = app.net_input_fields{i}.draw(x, y, app.NetInputsPanel, app.NetworkLevelAnalysisUIFigure);
                app.net_input_fields{i}.read(app.net_input_struct);
                y = y - h;
            end
        end

        % Value changed function: FullConnCheckBox, 
        % NonPermutedCheckBox, WithinNetPairCheckBox
        function MethodButtonGroupSelectionChanged(app, event)
            if ~(app.net_input_struct.full_connectome == app.FullConnCheckBox.Value)
                app.WithinNetPairCheckBox.Value = false;
            elseif ~(app.net_input_struct.within_network_pair == app.WithinNetPairCheckBox.Value)
                app.FullConnCheckBox.Value = true;
            else
                return
            end
            
            app.net_input_struct.no_permutations = app.NonPermutedCheckBox.Value;
            app.net_input_struct.full_connectome = app.FullConnCheckBox.Value;
            app.net_input_struct.within_network_pair = app.WithinNetPairCheckBox.Value;
            
            % remove permutation count when nonpermuted selected
            if app.net_input_struct.full_connectome
                app.PermutationcountEditField.Enable = true;
                app.PermutationcountEditField.Value = app.net_input_struct.perm_count;
            else
                app.PermutationcountEditField.Enable = false;
                app.PermutationcountEditField.Value = 0;
            end
        end

        % Value changed function: PermutationcountEditField
        function PermutationcountEditFieldValueChanged(app, event)
            app.net_input_struct.perm_count = app.PermutationcountEditField.Value;
            app.input_struct.perm_count = app.PermutationcountEditField.Value;
        end

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)
            if ~isfield(app.input_struct, "permutation_groups") || isfield(app.input_struct, "permutation_groups") && (isequal(app.input_struct.permutation_groups, false) || isempty(app.input_struct.permutation_groups))
                app.input_struct.permute_method = nla.edge.permutationMethods.BehaviorVec();
            else
                app.input_struct.permute_method = nla.edge.permutationMethods.MultiLevel();
                app.input_struct.permute_method = app.input_struct.permute_method.createPermutationTree(app.input_struct);
            end
            runWithInputs(app, 0);
        end

        % Button pushed function: NoneButton
        function NoneButtonPushed(app, event)
            import nla.*
            
            tests = app.NetTestSelector.Value;
            app.test_pool.net_tests = tests;
            
            % store old input fields and undraw
            for i = 1:numel(app.net_input_fields)
                app.net_input_struct = app.net_input_fields{i}.store(app.net_input_struct);
                app.net_input_fields{i}.undraw();
            end
            
            app.NetTestSelector.Value = {};
            app.net_input_fields = {};
            app.test_pool.net_tests = {};
        end

        % Menu selected function: OpenpreviousresultMenu
        function OpenpreviousresultMenuSelected(app, event)
            [file, path, idx] = uigetfile({'*.mat', 'Results (*.mat)'}, 'Select Previous Result'); %TODO add all file options readtable can read from
            
            if idx ~= 0
                prog = uiprogressdlg(app.NetworkLevelAnalysisUIFigure, 'Title', 'Loading previous result', 'Message', sprintf('Loading %s', file), 'Indeterminate', true);
                drawnow;
                
                [results, old_data] = nla.net.result.NetworkTestResult().loadPreviousData([path file]);
                
                try
%                     results_file = load([path file]);
                    if isa(results, 'nla.ResultPool')
                        NLAResult(results, file, false, old_data);
                    end
                    close(prog);
                catch ex
                    close(prog);
                    uialert(app.NetworkLevelAnalysisUIFigure, ex.message, 'Error while loading previous result');
                end
                close(prog)
            end
        end

        % Button pushed function: RunQualityControlButton
        function RunQualityControlButtonPushed(app, event)
            import nla.*
            runWithInputs(app, 1);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create NetworkLevelAnalysisUIFigure and hide until all components are created
            app.NetworkLevelAnalysisUIFigure = uifigure('Visible', 'off');
            app.NetworkLevelAnalysisUIFigure.Position = [100 100 1151 718];
            app.NetworkLevelAnalysisUIFigure.Name = 'NetworkLevelAnalysis';

            % Create FileMenu
            app.FileMenu = uimenu(app.NetworkLevelAnalysisUIFigure);
            app.FileMenu.Text = 'File';

            % Create OpenpreviousresultMenu
            app.OpenpreviousresultMenu = uimenu(app.FileMenu);
            app.OpenpreviousresultMenu.MenuSelectedFcn = createCallbackFcn(app, @OpenpreviousresultMenuSelected, true);
            app.OpenpreviousresultMenu.Accelerator = 'o';
            app.OpenpreviousresultMenu.Text = 'Open previous result';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.NetworkLevelAnalysisUIFigure);
            app.GridLayout.ColumnWidth = {'1x', 598};
            app.GridLayout.RowHeight = {38, 100, '1x', 53, 1};
            app.GridLayout.ColumnSpacing = 8.66666666666667;
            app.GridLayout.RowSpacing = 3.4;
            app.GridLayout.Padding = [8.66666666666667 3.4 8.66666666666667 3.4];

            % Create Panel_3
            app.Panel_3 = uipanel(app.GridLayout);
            app.Panel_3.BorderType = 'none';
            app.Panel_3.Layout.Row = [1 2];
            app.Panel_3.Layout.Column = 2;

            % Create NoneButton
            app.NoneButton = uibutton(app.Panel_3, 'push');
            app.NoneButton.ButtonPushedFcn = createCallbackFcn(app, @NoneButtonPushed, true);
            app.NoneButton.Position = [85 80 48 21];
            app.NoneButton.Text = 'None';

            % Create NetTestSelector
            app.NetTestSelector = uilistbox(app.Panel_3);
            app.NetTestSelector.Items = {};
            app.NetTestSelector.Multiselect = 'on';
            app.NetTestSelector.ValueChangedFcn = createCallbackFcn(app, @NetTestSelectorValueChanged, true);
            app.NetTestSelector.Position = [146 2 182 138];
            app.NetTestSelector.Value = {};

            % Create NetworkleveltestsCtrlclickformultipleLabel
            app.NetworkleveltestsCtrlclickformultipleLabel = uilabel(app.Panel_3);
            app.NetworkleveltestsCtrlclickformultipleLabel.HorizontalAlignment = 'right';
            app.NetworkleveltestsCtrlclickformultipleLabel.Position = [6 110 125 28];
            app.NetworkleveltestsCtrlclickformultipleLabel.Text = {'Network-level tests'; '(Ctrl+click for multiple)'};

            % Create BranchLabel
            app.BranchLabel = uilabel(app.Panel_3);
            app.BranchLabel.HorizontalAlignment = 'right';
            app.BranchLabel.FontColor = [0.8 0.8 0.8];
            app.BranchLabel.Position = [336 123 263 22];
            app.BranchLabel.Text = 'gui | unknown_branch:0000000';

            % Create EdgeInputsPanel
            app.EdgeInputsPanel = uipanel(app.GridLayout);
            app.EdgeInputsPanel.Title = 'Edge-level inputs';
            app.EdgeInputsPanel.Layout.Row = [2 4];
            app.EdgeInputsPanel.Layout.Column = 1;

            % Create NetInputsPanel
            app.NetInputsPanel = uipanel(app.GridLayout);
            app.NetInputsPanel.Title = 'Network-level inputs';
            app.NetInputsPanel.Layout.Row = 3;
            app.NetInputsPanel.Layout.Column = 2;

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.AutoResizeChildren = 'off';
            app.Panel.BorderType = 'none';
            app.Panel.Layout.Row = 1;
            app.Panel.Layout.Column = 1;

            % Create EdgeTestSelector
            app.EdgeTestSelector = uidropdown(app.Panel);
            app.EdgeTestSelector.Items = {};
            app.EdgeTestSelector.ValueChangedFcn = createCallbackFcn(app, @EdgeTestSelectorValueChanged, true);
            app.EdgeTestSelector.Position = [101 3 212 33];
            app.EdgeTestSelector.Value = {};

            % Create EdgeleveltestDropDownLabel
            app.EdgeleveltestDropDownLabel = uilabel(app.Panel);
            app.EdgeleveltestDropDownLabel.HorizontalAlignment = 'right';
            app.EdgeleveltestDropDownLabel.Position = [1 8 85 22];
            app.EdgeleveltestDropDownLabel.Text = 'Edge-level test';

            % Create Panel_2
            app.Panel_2 = uipanel(app.GridLayout);
            app.Panel_2.AutoResizeChildren = 'off';
            app.Panel_2.BorderType = 'none';
            app.Panel_2.Layout.Row = 4;
            app.Panel_2.Layout.Column = 2;

            % Create RunButton
            app.RunButton = uibutton(app.Panel_2, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.Position = [544 3 53 20];
            app.RunButton.Text = 'Run';

            % Create MethodsPanel
            app.MethodsPanel = uipanel(app.Panel_2);
            app.MethodsPanel.AutoResizeChildren = 'off';
            app.MethodsPanel.Title = 'Methods';
            app.MethodsPanel.Position = [1 2 345 48];

            % Create NonPermutedCheckBox
            app.NonPermutedCheckBox = uicheckbox(app.MethodsPanel);
            app.NonPermutedCheckBox.ValueChangedFcn = createCallbackFcn(app, @MethodButtonGroupSelectionChanged, true);
            app.NonPermutedCheckBox.Tag = 'nonpermuted';
            app.NonPermutedCheckBox.Enable = 'off';
            app.NonPermutedCheckBox.Text = 'Non-permuted';
            app.NonPermutedCheckBox.Position = [10 3 99 22];
            app.NonPermutedCheckBox.Value = true;

            % Create FullConnCheckBox
            app.FullConnCheckBox = uicheckbox(app.MethodsPanel);
            app.FullConnCheckBox.ValueChangedFcn = createCallbackFcn(app, @MethodButtonGroupSelectionChanged, true);
            app.FullConnCheckBox.Tag = 'full_con';
            app.FullConnCheckBox.Text = 'Full connectome';
            app.FullConnCheckBox.Position = [118 3 110 22];
            app.FullConnCheckBox.Value = true;

            % Create WithinNetPairCheckBox
            app.WithinNetPairCheckBox = uicheckbox(app.MethodsPanel);
            app.WithinNetPairCheckBox.ValueChangedFcn = createCallbackFcn(app, @MethodButtonGroupSelectionChanged, true);
            app.WithinNetPairCheckBox.Tag = 'within_net_pair';
            app.WithinNetPairCheckBox.Text = 'Within Net-pair';
            app.WithinNetPairCheckBox.Position = [236 3 101 22];
            app.WithinNetPairCheckBox.Value = true;

            % Create RunQualityControlButton
            app.RunQualityControlButton = uibutton(app.Panel_2, 'push');
            app.RunQualityControlButton.ButtonPushedFcn = createCallbackFcn(app, @RunQualityControlButtonPushed, true);
            app.RunQualityControlButton.Position = [472 29 125 21];
            app.RunQualityControlButton.Text = 'Run Quality Control';

            % Create PermutationcountLabel
            app.PermutationcountLabel = uilabel(app.Panel_2);
            app.PermutationcountLabel.HorizontalAlignment = 'right';
            app.PermutationcountLabel.Position = [359 2 106 22];
            app.PermutationcountLabel.Text = 'Permutation count:';

            % Create PermutationcountEditField
            app.PermutationcountEditField = uieditfield(app.Panel_2, 'numeric');
            app.PermutationcountEditField.Limits = [0 Inf];
            app.PermutationcountEditField.RoundFractionalValues = 'on';
            app.PermutationcountEditField.ValueDisplayFormat = '%11d';
            app.PermutationcountEditField.ValueChangedFcn = createCallbackFcn(app, @PermutationcountEditFieldValueChanged, true);
            app.PermutationcountEditField.Position = [480 2 53 22];
            app.PermutationcountEditField.Value = 10000;

            % Show the figure after all components are created
            app.NetworkLevelAnalysisUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = NLA_GUI

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.NetworkLevelAnalysisUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.NetworkLevelAnalysisUIFigure)
        end
    end
end