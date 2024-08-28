classdef NLAResult < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        FileMenu                   matlab.ui.container.Menu
        SaveButton                 matlab.ui.container.Menu
        ResultTree                 matlab.ui.container.Tree
        FlipNestingButton          matlab.ui.control.Button
        EdgeLevelLabel             matlab.ui.control.Label
        ViewEdgeLevelButton        matlab.ui.control.Button
        NetLevelLabel              matlab.ui.control.Label
        RunButton                  matlab.ui.control.Button
        SaveSummaryTable           matlab.ui.control.Button
        AdjustableNetParamsPanel   matlab.ui.container.Panel
        BranchLabel                matlab.ui.control.Label
        OpenTriMatrixPlotButton    matlab.ui.control.Button
        OpenDiagnosticPlotsButton  matlab.ui.control.Button
    end

    
    properties (Access = private)
        input_struct
        net_input_struct
        test_pool = false
        edge_result = false
        results = false
        nesting_by_method = true
        prog_bar = false
        net_adjustable_fields
        cur_iter = 0
    end
    
    methods (Access = private)
        function node = createNode(app, parent, text, node_data)
            import nla.* % required due to matlab package system quirks
            node = uitreenode(parent);
            node.Text = text;
            if exist('node_data', 'var')
                node.NodeData = node_data;
            end
        end
        
        function moveCurrFigToParentLocation(app)
            
            currPos = get(gcf, 'Position');
            
            currWidth = currPos(3);
            currHeight = currPos(4);
            
            appWindowPos = app.UIFigure.Position;
            
            %Position sets bottom left of figure, but we want to match the
            %top left (to ensure that top of new figure is on screen()
            vertOffset = currHeight - appWindowPos(4);
            
            additionalOffset = [10, -10];
            
            moveFigTo_x = appWindowPos(1) + additionalOffset(1);
            moveFigTo_y = appWindowPos(2) + additionalOffset(2) - vertOffset;
            
                        
            set(gcf, 'Position', [moveFigTo_x moveFigTo_y currWidth currHeight]);
        
        end
        
        function setNesting(app, nesting_by_method)
            import nla.* % required due to matlab package system quirks
            % clear old nodes
            for i = 1:size(app.ResultTree.Children, 1)
                for j = 1:size(app.ResultTree.Children(1).Children, 1)
                    delete(app.ResultTree.Children(1).Children(1));
                end
                delete(app.ResultTree.Children(1))
            end
            
            % add new nodes
            if nesting_by_method
                if app.net_input_struct.no_permutations
                    root = app.createNode(app.ResultTree, 'Non-permuted');
                    for i = 1:size(app.results.network_test_results, 2)
                        result = app.results.network_test_results{i};
                        % All our tests have non-permuted data
                        flags = struct();
                        flags.show_nonpermuted = true;
                        app.createNode(root, result.test_display_name, {result, flags});
                    end
                end
                
                if app.net_input_struct.full_connectome
                    root = app.createNode(app.ResultTree, 'Full connectome');
                    for i = 1:size(app.results.permutation_network_test_results, 2)
                        result = app.results.permutation_network_test_results{i};
                        if ~isequal(result.full_connectome, false)
                            flags = struct();
                            flags.show_full_conn = true;
                            app.createNode(root, result.test_display_name, {result, flags});
                        end
                    end
                end
                
                if app.net_input_struct.within_network_pair
                    root = app.createNode(app.ResultTree, 'Within Net-pair');
                    for i = 1:size(app.results.permutation_network_test_results, 2)
                        result = app.results.permutation_network_test_results{i};
                        if ~isequal(result.within_network_pair, false)
                            flags = struct();
                            flags.show_within_net_pair = true;
                            app.createNode(root, result.test_display_name, {result, flags});
                        end
                    end
                end
            else
                for i = 1:size(app.results.network_test_results, 2)
                    root = app.createNode(app.ResultTree, app.results.network_test_results{i}.test_display_name);
                    
                    result = app.results.network_test_results{i};
                    if app.net_input_struct.no_permutations 
                        flags = struct();
                        flags.show_nonpermuted = true;
                        app.createNode(root, 'Non-permuted', {result, flags});
                    end
                    
                    if app.net_input_struct.full_connectome && result.has_full_conn
                        perm_result = app.results.permutation_network_test_results{i};
                        if app.net_input_struct.full_connectome && ~isequal(result.full_connectome, false)
                            flags = struct();
                            flags.show_full_conn = true;
                            app.createNode(root, 'Full connectome', {perm_result, flags});
                        end
                        if app.net_input_struct.within_network_pair && ~isequal(result.within_network_pair, false)
                            flags = struct();
                            flags.show_within_net_pair = true;
                            app.createNode(root, 'Within Net-pair', {perm_result, flags});
                        end
                    end
                end
            end
        end
        
        function updateProgPermStats(app, ~)
            if ~islogical(app.prog_bar)
                app.cur_iter = app.cur_iter + 1;
                if app.cur_iter < app.net_input_struct.perm_count
                    app.prog_bar.Message = sprintf('Running edge-level statistics (%d/%d permutations)', mod(app.cur_iter, app.net_input_struct.perm_count), app.net_input_struct.perm_count);
                else
                    app.prog_bar.Message = sprintf('Running net-level statistics (%d/%d permutations)', mod(app.cur_iter, app.net_input_struct.perm_count), app.net_input_struct.perm_count);
                end
                
                app.prog_bar.Value = mod(app.cur_iter, app.net_input_struct.perm_count) ./ app.net_input_struct.perm_count;
                if app.prog_bar.CancelRequested
                    pool = gcp('nocreate');
                    delete(pool);
                    close(app.prog_bar);
                end
            end
        end
        
        function genadjustableNetParams(app)
            import nla.* % required due to matlab package system quirks
            
            % disgusting special case
            if isfield(app.net_input_struct, 'prob_max_original')
                app.net_input_struct.prob_max = app.net_input_struct.prob_max_original;
            end
            
            results = app.results.network_test_results;
            
            % required inputs to run these tests
            inputs = {};
            for i = 1:numel(results)
                inputs = cat(2, inputs, results{i}.editableOptions());
            end
            app.net_adjustable_fields = inputField.reduce(inputs);
            
            % display input fields
            x = inputField.LABEL_GAP * 2;
            y = app.AdjustableNetParamsPanel.InnerPosition(4);
            for i = 1:numel(app.net_adjustable_fields)
                y = y - inputField.LABEL_GAP;
                [w, h] = app.net_adjustable_fields{i}.draw(x, y, app.AdjustableNetParamsPanel, app.UIFigure);
                app.net_adjustable_fields{i}.read(app.net_input_struct);
                y = y - h;
            end
        end
        
        function readNetParamAdjustments(app)
            import nla.* % required due to matlab package system quirks
            
            [error_str, satisfied] = validateInputStruct(app.net_adjustable_fields, 'Must satisfy fields:', true);
            
            if satisfied
                error_str = "";
                errors_found = false;
                
                % store adjustable fields
                for i = 1:numel(app.net_adjustable_fields)
                    [app.net_input_struct, error] = app.net_adjustable_fields{i}.store(app.net_input_struct);
                    if ~islogical(error)
                        error_str = [error_str sprintf('\n - %s: %s', app.net_adjustable_fields{i}.disp_name, error)];
                        errors_found = true;
                    end
                end
                
                if errors_found
                    uialert(app.UIFigure, error_str, 'Error with adjustable field (using previous settings)');
                else
                    % disgusting special case
                    if isfield(app.net_input_struct, 'prob_max') && isfield(app.net_input_struct, 'behavior_count')
                        app.net_input_struct.prob_max_original = app.net_input_struct.prob_max;
                        app.net_input_struct.prob_max = app.net_input_struct.prob_max / app.net_input_struct.behavior_count;
                    end
                end
            else
                % TODO ideally buttons would just stay greyed out until
                % all inputs were satisfied
                uialert(app.UIFigure, error_str, 'adjustable field not satisfied (using previous settings)');
            end
        end
        
        function initFromInputs(app, test_pool, input_struct, net_input_struct)
            import nla.* % required due to matlab package system quirks
            app.ViewEdgeLevelButton.Enable = false;
            app.RunButton.Enable = false;
            if numel(test_pool.net_tests) == 0
                app.RunButton.Visible = false;
            end
            app.SaveButton.Enable = false;
            
            enableNetButtons(app, false);
            
            branchLabel(app, helpers.git.commitString(), helpers.git.commitString());
            app.EdgeLevelLabel.Text = test_pool.edge_test.name;
            
            prog = uiprogressdlg(app.UIFigure, 'Title', 'Running edge-level statistic', 'Message', sprintf('Running %s (non-permuted)', test_pool.edge_test.name), 'Indeterminate', true);
            drawnow;
            
            app.edge_result = test_pool.runEdgeTest(input_struct);
            
            app.input_struct = input_struct;
            app.net_input_struct = net_input_struct;
            app.test_pool = test_pool;

            app.ViewEdgeLevelButton.Enable = true;
            app.SaveButton.Enable = true;
            app.RunButton.Enable = true;
        
            close(prog);
        end
        
        function initFromResult(app, result, file_name)
            import nla.* % required due to matlab package system quirks
            app.UIFigure.Name = sprintf('%s - NLA Result', file_name);
            
            if (isstruct(result) && ~isfield(result, "commit_short")) || ~isprop(result, "commit_short")
                commit_short = "";
            else
                commit_short = result.commit_short();
            end
            branchLabel(app, helpers.git.commitString(), commit_short);
            
            if isprop(result, "edge_test_results") % We're basically checking for NetworkTestResult object or older here
                app.EdgeLevelLabel.Text = result.edge_test_results.name;
                app.input_struct = result.test_options;
                app.net_input_struct = result.network_test_options;
                app.edge_result = result.edge_test_results;
            else
                app.EdgeLevelLabel.Text = result.edge_result.name;
                app.input_struct = result.input_struct;
                app.net_input_struct = result.net_input_struct;
                app.edge_result = result.edge_result;
            end
            
            if isfield(app.net_input_struct, 'prob_max_original')
                app.net_input_struct.prob_max = app.net_input_struct.prob_max_original;
            end
            
            app.results = result;
            
            app.ViewEdgeLevelButton.Enable = true;
            app.SaveButton.Enable = true;
            app.RunButton.Enable = false;
            app.RunButton.Visible = false;
            
            enableNetButtons(app, ~islogical(result.network_test_results));
            
            drawnow();
            
            if ~islogical(result.network_test_results)
                app.setNesting(true);
            else
                app.results = false;
            end
            
            if ~islogical(result.network_test_results)
                app.genadjustableNetParams();
            end
        end
        
        function enableNetButtons(app, val)
            % buttons that need net-level data to be used
            net_buttons = {app.ResultTree, app.FlipNestingButton, app.SaveSummaryTable};
            for i = 1:numel(net_buttons)
                net_buttons{i}.Enable = val;
            end
            
            net_inputs_enabled = val;
            if ~isfield(app.net_input_struct, 'behavior_count') || ~isfield(app.net_input_struct, 'prob_max')
                net_inputs_enabled = false;
            end
            
            if net_inputs_enabled
                app.AdjustableNetParamsPanel.Enable = 'on';
            else
                app.AdjustableNetParamsPanel.Enable = 'off';
            end
            
            % dropdowns that need net-level data to be used
%             net_dropdowns = {app.FDRCorrection, app.EdgeLevelTypeDropDown, app.NetlevelplottingDropDown};
%             for i = 1:numel(net_dropdowns)
%                 net_dropdowns{i}.Enable = val;
%                 net_dropdowns{i}.ValueChangedFcn(app, true);
%             end
        end
        
        function displayManyPlots(app, extra_flags, plot_type)
            import nla.* % required due to matlab package system quirks
            
            app.readNetParamAdjustments();
            
            prog = uiprogressdlg(app.UIFigure, 'Title', sprintf('Generating %s', plot_type), 'Message', sprintf('Generating %s', plot_type));
            prog.Value = 0.02;
            drawnow;
            
            selected_nodes = app.ResultTree.SelectedNodes;
            for i = 1:size(selected_nodes, 1)
                if ~isempty(selected_nodes(i).NodeData)
                    result = selected_nodes(i).NodeData{1};
                    node_flags = selected_nodes(i).NodeData{2};
                    
                    prog.Message = sprintf('Generating %s %s', result.test_display_name, plot_type);
                    
                    result.output(app.input_struct, app.net_input_struct, app.input_struct.net_atlas, app.edge_result, helpers.mergeStruct(node_flags, extra_flags));
                    
                    prog.Value = i / size(selected_nodes, 1);
%                     app.moveCurrFigToParentLocation();
                end
            end
            
            close(prog);
        end
        
        function branchLabel(app, gui, result)
            app.BranchLabel.Text = sprintf('gui | %s\nresult | %s', gui, result);
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, test_pool, input_struct, net_input_struct)
            import nla.* % required due to matlab package system quirks
            
            app.UIFigure.Name = 'NLA Result';
            app.UIFigure.Icon = [findRootPath() 'thumb.png'];
            
            if isa(test_pool, 'nla.ResultPool')
                initFromResult(app, test_pool, input_struct);
            else
                initFromInputs(app, test_pool, input_struct, net_input_struct);
            end
        end

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)
            import nla.* % required due to matlab package system quirks
            prog = uiprogressdlg(app.UIFigure, 'Title', 'Running statistics', 'Message', 'Running net-level statistics', 'Cancelable', 'on');
            prog.Value = 0.02;
            drawnow;
            
            net_results = app.test_pool.runNetTests(app.net_input_struct, app.edge_result, app.input_struct.net_atlas, false);
            
            if app.net_input_struct.full_connectome
                prog.Message = 'Starting parallel pool...';
                prog.Value = 0.05;
                
                gcp;
                
                prog.Message = sprintf('Running net-level statistics (0/%d permutations)', app.net_input_struct.perm_count);
                prog.Value = 0;
                
                % Set handle reference
                app.prog_bar = prog;
                
                app.cur_iter = 0;
                
                % Data queue to output iteration # from parallel pool
                data_queue = parallel.pool.DataQueue;
                afterEach(data_queue, @app.updateProgPermStats);

                % Run permuted statistics
                app.test_pool.data_queue = data_queue;
                app.results = app.test_pool.runPerm(app.input_struct, app.net_input_struct, app.input_struct.net_atlas, app.edge_result, net_results, app.net_input_struct.perm_count);
                
                % Delete the data queue
                delete(data_queue);
                
                % Unset handle reference
                app.prog_bar = false;
            else
                app.results = ResultPool(app.input_struct, app.net_input_struct, app.input_struct.net_atlas, app.edge_result, net_results, false, false);
            end
            
            prog.Value = 0.98;
            
            app.RunButton.Enable = false;
            app.RunButton.Visible = false;
            
            enableNetButtons(app, true);
            
            drawnow();
            
            app.setNesting(true);
            app.genadjustableNetParams();
            
            close(prog);
        end

        % Menu selected function: SaveButton
        function SaveButtonPushed(app, event)
            import nla.* % required due to matlab package system quirks
            
            app.readNetParamAdjustments();
            
            if islogical(app.results)
                % save just edge-level results
                result = ResultPool(app.input_struct, app.net_input_struct, app.input_struct.net_atlas, app.edge_result, false, false, false);
            else
                result = app.results;
                
                result.test_options = app.input_struct;
                result.network_test_options = app.net_input_struct;
                result.edge_test_results = app.edge_result;
            end
            
            [file, path] = uiputfile({'*.mat', 'Result (*.mat)'}, 'Save Result File', 'result.mat');
            if file ~= 0
                prog = uiprogressdlg(app.UIFigure, 'Title', 'Saving results', 'Message', sprintf('Saving to %s', file), 'Indeterminate', true);
                drawnow;
                
                result.to_file([path file]);
                
                app.UIFigure.Name = sprintf('%s - NLA Result', file);
                
                close(prog);
            end
        end

        % Button pushed function: FlipNestingButton
        function FlipNestingButtonPushed(app, event)
            import nla.* % required due to matlab package system quirks
            app.nesting_by_method = ~app.nesting_by_method;
            app.setNesting(app.nesting_by_method)
        end

        % Button pushed function: ViewEdgeLevelButton
        function ViewEdgeLevelButtonPushed(app, event)
            import nla.* % required due to matlab package system quirks
            prog = uiprogressdlg(app.UIFigure, 'Title', 'Generating figures', 'Message', sprintf('Generating %s figures', app.edge_result.name), 'Indeterminate', true);
            drawnow;
            
            flags = struct();
            flags.display_sig = true;
            
            app.edge_result.output(app.input_struct.net_atlas, flags)
            
            close(prog);
            
%             app.moveCurrFigToParentLocation();
            
        end

        % Button pushed function: OpenTriMatrixPlotButton
        function DisplaySelectedButtonPushed(app, event)
            import nla.* % required due to matlab package system quirks
            displayManyPlots(app, struct('plot_type', PlotType.FIGURE), 'figures');
        end

        % Callback function
        function PValModeDropDownValueChanged(app, event)
            import nla.* % required due to matlab package system quirks
            value = app.NetlevelplottingDropDown.Value;
            if strcmp(value, 'linear')
                % Plot p-values on linear scale
                app.net_input_struct.prob_plot_method = gfx.ProbPlotMethod.DEFAULT;
            elseif strcmp(value, 'p-value log')
                % Plot p-values on logarithmic scale
                app.net_input_struct.prob_plot_method = gfx.ProbPlotMethod.LOG;
            elseif strcmp(value, 'p-value -log')
                % Plot p-values on negative logarithmic scale
                app.net_input_struct.prob_plot_method = gfx.ProbPlotMethod.NEG_LOG_10;
            else
                app.net_input_struct.prob_plot_method = gfx.ProbPlotMethod.STATISTIC;
            end
        end

        % Callback function
        function DisplayConvergenceButtonPushed(app, event)
            import nla.* % required due to matlab package system quirks
            
            app.readNetParamAdjustments();
            
            prog = uiprogressdlg(app.UIFigure, 'Title', sprintf('Generating convergence map'), 'Message', 'Generating net-level convergence map');
            prog.Value = 0.02;
            drawnow;
            
            num_tests = 0;
            sig_count_mat = TriMatrix(app.input_struct.net_atlas.numNets(), 'double', TriMatrixDiag.KEEP_DIAGONAL);
            names = [];
            
            selected_nodes = app.ResultTree.SelectedNodes;
            for i = 1:size(selected_nodes, 1)
                if ~isempty(selected_nodes(i).NodeData)
                    result = selected_nodes(i).NodeData{1};
                    flags = selected_nodes(i).NodeData{2};
                    
                    [num_tests_part, sig_count_mat_part, names_part] = result.getSigMat(app.net_input_struct, app.input_struct.net_atlas, flags);
                    num_tests = num_tests + num_tests_part;
                    sig_count_mat.v = sig_count_mat.v + sig_count_mat_part.v;
                    names = [names names_part];
                    
                    prog.Value = i / size(selected_nodes, 1);
                end
            end
            
            color_map_idx = app.ColormapDropDown.Value;
            
            if color_map_idx == 1
                color_map = flip(bone());
            elseif color_map_idx == 2
                color_map = [[1,1,1]; flip(winter())];
            elseif color_map_idx == 3
                color_map = [[1,1,1]; flip(autumn())];
            elseif color_map_idx == 4
                color_map = [[1,1,1]; flip(copper())];
            end 
            
            gfx.drawConvergenceMap(app.input_struct, app.net_input_struct, app.input_struct.net_atlas, sig_count_mat, num_tests, names, app.edge_result, color_map);
            
            close(prog);
            
%             app.moveCurrFigToParentLocation();
            %These mlapp files are really just the worst
        end

        % Callback function
        function DisplayChordNetButtonPushed(app, event)
            import nla.* % required due to matlab package system quirks
            displayManyPlots(app, struct('plot_type', PlotType.CHORD), 'chord plots');
        end

        % Callback function
        function DisplayChordEdgeButtonPushed(app, event)
            import nla.* % required due to matlab package system quirks
            displayManyPlots(app, struct('plot_type', PlotType.CHORD_EDGE), 'chord plots');
        end

        % Button pushed function: SaveSummaryTable
        function SaveSummaryTableButtonPushed(app, event)
            import nla.* % required due to matlab package system quirks
            [file, path] = uiputfile({'*.txt', 'Summary Table (*.txt)'}, 'Save Summary Table', 'result.txt');
            if file ~= 0
                prog = uiprogressdlg(app.UIFigure, 'Title', 'Saving summary table', 'Message', sprintf('Saving to %s', file), 'Indeterminate', true);
                drawnow;
                
                app.results.saveSummaryTable([path file]);
                
                close(prog);
            end
        end

        % Callback function
        function EdgeLevelTypeDropDownValueChanged(app, event)
            import nla.* % required due to matlab package system quirks
            value = app.EdgeLevelTypeDropDown.Value;
            if strcmp(value, 'prob')
                app.net_input_struct.edge_chord_plot_method = gfx.EdgeChordPlotMethod.PROB;
            elseif strcmp(value, 'coeff')
                app.net_input_struct.edge_chord_plot_method = gfx.EdgeChordPlotMethod.COEFF;
            elseif strcmp(value, 'coeff (split)')
                app.net_input_struct.edge_chord_plot_method = gfx.EdgeChordPlotMethod.COEFF_SPLIT;
            elseif strcmp(value, 'coeff (basic)')
                app.net_input_struct.edge_chord_plot_method = gfx.EdgeChordPlotMethod.COEFF_BASE;
            else
                app.net_input_struct.edge_chord_plot_method = gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT;
            end
        end

        % Callback function
        function FDRCorrectionValueChanged(app, event)
            import nla.* % required due to matlab package system quirks
            value = app.FDRCorrection.Value;
            if strcmp(value, 'Benjamini-Hochberg')
                app.net_input_struct.fdr_correction = net.mcc.BenjaminiHochberg();
            elseif strcmp(value, 'Benjamini-Yekutieli')
                app.net_input_struct.fdr_correction = net.mcc.BenjaminiYekutieli();
            else
                app.net_input_struct.fdr_correction = net.mcc.Bonferroni();
            end
        end

        % Callback function
        function showROIcentroidsinbrainplotsCheckBoxValueChanged(app, event)
            include_centroids = app.showROIcentroidsinbrainplotsCheckBox.Value;
            app.net_input_struct.show_ROI_centroids = include_centroids;
        end

        % Callback function
        function CohensDthresholdchordplotsCheckBoxValueChanged(app, event)
            d_thresh = app.CohensDthresholdchordplotsCheckBox.Value;
            app.net_input_struct.d_thresh_chord_plot = d_thresh;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 858 659];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create SaveButton
            app.SaveButton = uimenu(app.FileMenu);
            app.SaveButton.MenuSelectedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Accelerator = 's';
            app.SaveButton.Text = 'Save';

            % Create ResultTree
            app.ResultTree = uitree(app.UIFigure);
            app.ResultTree.Multiselect = 'on';
            app.ResultTree.Position = [9 10 418 562];

            % Create FlipNestingButton
            app.FlipNestingButton = uibutton(app.UIFigure, 'push');
            app.FlipNestingButton.ButtonPushedFcn = createCallbackFcn(app, @FlipNestingButtonPushed, true);
            app.FlipNestingButton.Position = [345 577 81 22];
            app.FlipNestingButton.Text = 'Flip nesting';

            % Create EdgeLevelLabel
            app.EdgeLevelLabel = uilabel(app.UIFigure);
            app.EdgeLevelLabel.Position = [9 633 275 22];
            app.EdgeLevelLabel.Text = 'Edge-level statistic';

            % Create ViewEdgeLevelButton
            app.ViewEdgeLevelButton = uibutton(app.UIFigure, 'push');
            app.ViewEdgeLevelButton.ButtonPushedFcn = createCallbackFcn(app, @ViewEdgeLevelButtonPushed, true);
            app.ViewEdgeLevelButton.Position = [9 610 47 22];
            app.ViewEdgeLevelButton.Text = 'View';

            % Create NetLevelLabel
            app.NetLevelLabel = uilabel(app.UIFigure);
            app.NetLevelLabel.Position = [9 573 302 22];
            app.NetLevelLabel.Text = 'Network-level statistics (Ctrl or Shift+click for multiple)';

            % Create RunButton
            app.RunButton = uibutton(app.UIFigure, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.Position = [18 523 49 40];
            app.RunButton.Text = 'Run';

            % Create SaveSummaryTable
            app.SaveSummaryTable = uibutton(app.UIFigure, 'push');
            app.SaveSummaryTable.ButtonPushedFcn = createCallbackFcn(app, @SaveSummaryTableButtonPushed, true);
            app.SaveSummaryTable.Position = [434 10 125 22];
            app.SaveSummaryTable.Text = 'Save summary table';

            % Create AdjustableNetParamsPanel
            app.AdjustableNetParamsPanel = uipanel(app.UIFigure);
            app.AdjustableNetParamsPanel.Title = 'Adjustable network-level parameters';
            app.AdjustableNetParamsPanel.Position = [434 170 416 427];

            % Create BranchLabel
            app.BranchLabel = uilabel(app.UIFigure);
            app.BranchLabel.HorizontalAlignment = 'right';
            app.BranchLabel.VerticalAlignment = 'top';
            app.BranchLabel.FontColor = [0.8 0.8 0.8];
            app.BranchLabel.Position = [434 627 418 29];
            app.BranchLabel.Text = {'gui | unknown_branch:0000000'; 'result produced by | unknown_branch:0000000'};

            % Create OpenTriMatrixPlotButton
            app.OpenTriMatrixPlotButton = uibutton(app.UIFigure, 'push');
            app.OpenTriMatrixPlotButton.ButtonPushedFcn = createCallbackFcn(app, @DisplaySelectedButtonPushed, true);
            app.OpenTriMatrixPlotButton.Position = [435 127 146 22];
            app.OpenTriMatrixPlotButton.Text = 'Open TriMatrix Plot';

            % Create OpenDiagnosticPlotsButton
            app.OpenDiagnosticPlotsButton = uibutton(app.UIFigure, 'push');
            app.OpenDiagnosticPlotsButton.Position = [435 98 147 22];
            app.OpenDiagnosticPlotsButton.Text = 'Open Diagnostic Plots';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = NLAResult(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end