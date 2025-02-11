classdef NetworkTestPlotApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        Menu                            matlab.ui.container.Menu
        SaveasMenu                      matlab.ui.container.Menu
        Panel                           matlab.ui.container.Panel
        PlotScaleDropDownLabel          matlab.ui.control.Label
        PlotScaleDropDown               matlab.ui.control.DropDown
        RankingDropDownLabel            matlab.ui.control.Label
        RankingDropDown                 matlab.ui.control.DropDown
        UpperLimitEditFieldLabel        matlab.ui.control.Label
        UpperLimitEditField             matlab.ui.control.NumericEditField
        LowerLimitEditFieldLabel        matlab.ui.control.Label
        LowerLimitEditField             matlab.ui.control.NumericEditField
        pvalueThresholdEditFieldLabel   matlab.ui.control.Label
        pvalueThresholdEditField        matlab.ui.control.NumericEditField
        CohensDThresholdEditFieldLabel  matlab.ui.control.Label
        CohensDThresholdEditField       matlab.ui.control.NumericEditField
        ColormapDropDownLabel           matlab.ui.control.Label
        ColormapDropDown                matlab.ui.control.DropDown
        LegendVisibleDropDownLabel      matlab.ui.control.Label
        LegendVisibleDropDown           matlab.ui.control.DropDown
        MultipleComparisonCorrectionDropDownLabel  matlab.ui.control.Label
        MultipleComparisonCorrectionDropDown  matlab.ui.control.DropDown
        CohensDThresholdCheckBox        matlab.ui.control.CheckBox
        ROIcentroidsonbrainplotsCheckBox  matlab.ui.control.CheckBox
        ViewChordPlotsButton            matlab.ui.control.Button
        ViewEdgeChordPlotsButton        matlab.ui.control.Button
        EdgeChordPlotTypeDropDownLabel  matlab.ui.control.Label
        EdgeChordPlotTypeDropDown       matlab.ui.control.DropDown
        ViewConvergenceMapButton        matlab.ui.control.Button
        ConvergencePlotColorDropDownLabel  matlab.ui.control.Label
        ConvergencePlotColorDropDown    matlab.ui.control.DropDown
        ApplyButton                     matlab.ui.control.Button
        Panel_2                         matlab.ui.container.Panel
    end

    
    properties (Access = public)
        network_test_result
        edge_test_result
        test_method
        edge_test_options
        network_test_options
        x_position
        y_position
        matrix_plot = false
        parameters
        title = ""
        chord_type = "nla.PlotType.CHORD"
        settings = false
    end
    
    properties (Dependent)
        is_noncorrelation_input
    end
    
    properties (Constant)
        colormap_choices = ["Parula", "Turbo", "HSV", "Hot", "Cool", "Spring", "Summer", "Autumn", "Winter", "Gray",...
            "Bone", "Copper", "Pink"] % Colorbar choices
        legend_visible = ["On", "Off"]
        COLORMAP_SAMPLE_COLORS = 16
    end
    
    methods
        %% getters for dependent props
        function value = get.is_noncorrelation_input(app)
            value = app.network_test_result.is_noncorrelation_input;
        end
        %%
    end
    
    methods (Access = public)        
        function getPlotTitle(app)
            app.title = "";
            % Building the plot title by going through options
            switch app.test_method
                case "no_permutations"
                    app.title = "Non-permuted Method\nNon-permuted Significance";
                case "full_connectome"
                    app.title = "Full Connectome Method\nNetwork vs. Connectome Significance";
                case "within_network_pair"
                    app.title = "Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair";
            end
            if isequal(app.CohensDThresholdCheckBox.Value, true)
                app.title = sprintf("%s (D > %g)", app.title, app.CohensDThresholdEditField.Value);
            end
            if ~isequal(app.test_method, "no_permutations")
                if isequal(app.RankingDropDown.Value, "nla.RankingMethod.WINKLER") % Look at me, I'm MATLAB. I have no idea why enums are beneficial or how to use them
                    app.title = strcat(app.title, "\nRanking by Winkler Method");
                elseif isequal(app.RankingDropDown.Value, "nla.RankingMethod.WESTFALL_YOUNG")
                    app.title = strcat(app.title, "\nRanking by Westfall-Young Method");
                else
                    app.title = strcat(app.title, "\nUncorrected data");
                end
            end
        end
        
        function [width, height] = drawTriMatrixPlot(app)
            import nla.net.result.NetworkTestResult
            
            if ~isequal(app.matrix_plot, false)
                app.settings = struct();
                app.settings.upperLimit = app.UpperLimitEditField.Value;
                app.settings.lowerLimit = app.LowerLimitEditField.Value;
                app.settings.plotScale = app.PlotScaleDropDown.Value;
                app.settings.pValueThreshold = app.pvalueThresholdEditField.Value;
                app.settings.cohensD = app.CohensDThresholdCheckBox.Value;
                app.settings.cohensDValue = app.CohensDThresholdEditField.Value;
                app.matrix_plot.plot_title.String = {};
                app.network_test_options.prob_max = app.pvalueThresholdEditField.Value;
            end

            switch app.MultipleComparisonCorrectionDropDown.Value
                case "Benjamini-Hochberg"
                    mcc = "BenjaminiHochberg";
                case "Benjamini-Yekutieli"
                    mcc = "BenjaminiYekutieli";
                otherwise
                    mcc = app.MultipleComparisonCorrectionDropDown.Value;
            end
            app.getPlotTitle();
            
            probability = NetworkTestResult().getPValueNames(app.test_method, app.network_test_result.test_name);
            
            app.network_test_options.show_ROI_centroids = app.ROIcentroidsonbrainplotsCheckBox.Value;
            
            app.parameters = nla.net.result.NetworkResultPlotParameter(app.network_test_result, app.edge_test_options.net_atlas,...
                app.network_test_options);
            
            probability_parameters = app.parameters.plotProbabilityParameters(app.edge_test_options, app.edge_test_result,...
                app.test_method, probability, sprintf(app.title), mcc, app.createSignificanceFilter(),...
                app.RankingDropDown.Value);
            
            if ~isequal(app.UpperLimitEditField.Value, 0.3) && ~isequal(app.LowerLimitEditField.Value, 0.3)
                probability_parameters.p_value_plot_max = app.UpperLimitEditField.Value;
            end
            
            plotter = nla.net.result.plot.PermutationTestPlotter(app.edge_test_options.net_atlas);
            [width, height, app.matrix_plot] = plotter.plotProbability(app.Panel_2, probability_parameters, nla.inputField.LABEL_GAP, -50);
            if ~isequal(app.settings, false)
                app.UpperLimitEditField.Value = app.settings.upperLimit;
                app.LowerLimitEditField.Value = app.settings.lowerLimit;
                app.PlotScaleDropDown.Value = app.settings.plotScale;
                app.pvalueThresholdEditField.Value = app.settings.pValueThreshold;
                app.CohensDThresholdCheckBox.Value = app.settings.cohensD;
                app.CohensDThresholdEditField.Value = app.settings.cohensDValue;
                app.applyScaleChange();
            end
        end
    end
    
    methods (Access = private)
        
        function cohens_d_filter = createSignificanceFilter(app)
            cohens_d_filter = nla.TriMatrix(app.edge_test_options.net_atlas.numNets, "logical", nla.TriMatrixDiag.KEEP_DIAGONAL);
            if isequal(app.CohensDThresholdCheckBox.Value, true)
                if isequal(app.test_method, "no_permutations") && ~isequal(app.network_test_result.no_permutations, false)
                    
                end
                if isequal(app.test_method, "full_connectome") && ~isequal(app.network_test_result.full_connectome, false)
                    cohens_d_filter.v = (app.network_test_result.full_connectome.d.v >= app.network_test_options.d_max);
                end
                if ~isequal(app.network_test_result.within_network_pair, false) && isfield(app.network_test_result.within_network_pair, "d")...
                    && ~isequal(app.test_method, "full_connectome")
                    cohens_d_filter.v = (app.network_test_result.within_network_pair.d.v >= app.network_test_options.d_max);
                end
            else
                cohens_d_filter.v = true(numel(cohens_d_filter.v), 1);   
            end
        end
        
        function applyScaleChange(app)
            progress_bar = uiprogressdlg(app.UIFigure, "Title", "Please Wait", "Message", "Applying Changes...", "Indeterminate", true);
            progress_bar.Message = "Chaning scale of existing TriMatrix...";
            app.matrix_plot.applyScale(false, false, app.UpperLimitEditField.Value, app.LowerLimitEditField.Value, app.PlotScaleDropDown.Value, app.ColormapDropDown.Value);
            app.matrix_plot.display_legend.Visible = lower(app.LegendVisibleDropDown.Value);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, network_test_result, edge_test_result, flags, edge_test_options, network_test_options, varargin)
            if isfield(flags, "show_nonpermuted") && flags.show_nonpermuted
                test_method = "no_permutations";
            elseif isfield(flags, "show_full_conn") && flags.show_full_conn
                test_method = "full_connectome";
            elseif isfield(flags, "show_within_net_pair") && flags.show_within_net_pair
                test_method = "within_network_pair";
            end
            app.network_test_result = network_test_result;
            app.edge_test_result = edge_test_result;
            app.test_method = test_method;
            app.edge_test_options = edge_test_options;
            app.network_test_options = network_test_options;
            
            % For some reason, MATLAB wouldn't accept this information in the gui editor. *&$*#(
            app.EdgeChordPlotTypeDropDown.Items = ["p-value", "Coefficient", "Coefficient (Split)", "Coefficient (Basic)", "Coefficient (Split, Basic)"];
            app.EdgeChordPlotTypeDropDown.ItemsData = ["nla.gfx.EdgeChordPlotMethod.PROB","nla.gfx.EdgeChordPlotMethod.COEFF","nla.gfx.EdgeChordPlotMethod.COEFF_SPLIT","nla.gfx.EdgeChordPlotMethod.COEFF_BASE","nla.gfx.EdgeChordPlotMethod.COEFF_BASE_SPLIT"];
            app.EdgeChordPlotTypeDropDown.Value = "nla.gfx.EdgeChordPlotMethod.PROB";
            
            app.edge_test_options.prob_max = app.pvalueThresholdEditField.Value;
            app.network_test_options.prob_max = app.pvalueThresholdEditField.Value;
            app.network_test_options.prob_plot_method = app.PlotScaleDropDown.Value;
            app.pvalueThresholdEditField.Value = app.network_test_options.prob_max;
            app.ColormapDropDown.Items = app.colormap_choices;
            app.ColormapDropDown.Value = app.colormap_choices{1};
            
            app.drawTriMatrixPlot()
        end

        % Callback function
        function drawChords(app, event)
            import nla.gfx.EdgeChordPlotMethod nla.net.result.NetworkTestResult
            
            app.getPlotTitle();
            
            plot_type = app.chord_type;
            
            probability = NetworkTestResult().getPValueNames(app.test_method, app.network_test_result.test_name);
            p_value = strcat("uncorrected_", probability);
            probability_parameters = app.parameters.plotProbabilityParameters(app.edge_test_options, app.edge_test_result,...
                app.test_method, p_value, sprintf(app.title), app.MultipleComparisonCorrectionDropDown.Value, app.createSignificanceFilter(),...
                app.RankingDropDown.Value);
            
            chord_plotter = nla.net.result.chord.ChordPlotter(app.edge_test_options.net_atlas, app.edge_test_result);
            
            probability_parameters.edge_chord_plot_method = app.EdgeChordPlotTypeDropDown.Value;
            chord_plotter.generateChordFigure(probability_parameters, plot_type)
        end

        % Value changed function: ColormapDropDown, 
        % LowerLimitEditField, 
        % MultipleComparisonCorrectionDropDown, PlotScaleDropDown, 
        % UpperLimitEditField
        function PlotScaleValueChanged(app, event)
            if isequal(app.settings, false)
                app.settings = struct();
            end
            app.settings.upperLimit = app.UpperLimitEditField.Value;
            app.settings.lowerLimit = app.LowerLimitEditField.Value;
            app.settings.plotScale = app.PlotScaleDropDown.Value;
            app.settings.pValueThreshold = app.pvalueThresholdEditField.Value;
            app.settings.cohensD = app.CohensDThresholdCheckBox.Value;
            app.settings.cohensDValue = app.CohensDThresholdEditField.Value;
            app.settings.RankingDropDown = app.RankingDropDown.Value;
        end

        % Value changed function: ROIcentroidsonbrainplotsCheckBox
        function ROIcentroidsonbrainplotsCheckBoxValueChanged(app, event)
            % This is used in brain plotting
            value = app.ROIcentroidsonbrainplotsCheckBox.Value;
            app.network_test_options.show_ROI_centroids = value;
        end

        % Value changed function: pvalueThresholdEditField
        function pvalueThresholdEditFieldValueChanged(app, event)
            % This is used in the trimatrix. It's applied during MCC, even if mcc='None'
            value = app.pvalueThresholdEditField.Value;
            app.network_test_options.prob_max = value;
        end

        % Button pushed function: ViewEdgeChordPlotsButton
        function ViewEdgeChordPlotsButtonPushed(app, event)
            app.chord_type = "nla.PlotType.CHORD_EDGE";
            app.drawChords(event);
        end

        % Value changed function: EdgeChordPlotTypeDropDown
        function EdgeChordPlotTypeDropDownValueChanged(app, event)
            value = app.EdgeChordPlotTypeDropDown.Value;
            app.network_test_options.edge_chord_plot_method = value;
        end

        % Button pushed function: ViewChordPlotsButton
        function ViewChordPlotsButtonPushed(app, event)
            app.chord_type = "nla.PlotType.CHORD";
            app.drawChords(event);
        end

        % Button pushed function: ApplyButton
        function ApplyButtonPushed(app, event)
            app.matrix_plot.color_bar.Ticks = [];
            app.drawTriMatrixPlot();
        end

        % Button pushed function: ViewConvergenceMapButton
        function ViewConvergenceMapButtonPushed(app, event)
            import nla.NetworkLevelMethod
            
            flags = struct();
            flags.show_full_conn = false;
            flags.show_within_net_pair = false;
            flags.show_nonpermuted = false;
            switch app.test_method
                case "no_permutations"
                    flags.show_nonpermuted = true;
                case "full_connectome"
                    flags.show_full_conn = true;
                case "within_network_pair"
                    flags.show_within_net_pair = true;
            end
            switch app.MultipleComparisonCorrectionDropDown.Value
                case "Benjamini-Hochberg"
                    app.network_test_options.fdr_correction = "BenjaminiHochberg";
                case "Benjamini-Yekutieli"
                    app.network_test_options.fdr_correction = "BenjaminiYekutieli";
                otherwise
                    app.network_test_options.fdr_correction = app.MultipleComparisonCorrectionDropDown.Value;
            end
            
            [test_number, significance_count_matrix, names] = app.network_test_result.getSigMat(app.network_test_options, app.edge_test_options.net_atlas, flags);
            
            colors = str2func(lower(app.ConvergencePlotColorDropDown.Value));
            if isequal(app.ConvergencePlotColorDropDown.Value, "Bone")
                color_map = flip(colors());
            else
                color_map = [[1, 1, 1]; flip(colors())];
            end

            nla.gfx.drawConvergenceMap(app.edge_test_options, app.network_test_options, app.edge_test_options.net_atlas, significance_count_matrix,...
                test_number, names, app.edge_test_result, color_map);
        end

        % Menu selected function: SaveasMenu
        function SaveasMenuSelected(app, event)
            trimatrix_default_name = strcat("nla_trimatrix_", datestr(datetime("now"), "yyyy_MM_dd"));
            [file, path] = uiputfile({'*.png', 'Image (*.png)'; '*.svg', 'Scalable Vector Graphic (*.svg)'}, "Save TriMatrix plot", trimatrix_default_name);
            if file ~= 0
                exportgraphics(app.matrix_plot.axes, fullfile(path, file));
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [1 1 1];
            app.UIFigure.Position = [100 100 674 835];
            app.UIFigure.Name = 'MATLAB App';

            % Create Menu
            app.Menu = uimenu(app.UIFigure);
            app.Menu.Text = 'File';

            % Create SaveasMenu
            app.SaveasMenu = uimenu(app.Menu);
            app.SaveasMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveasMenuSelected, true);
            app.SaveasMenu.Text = 'Save as...';

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.BackgroundColor = [1 1 1];
            app.Panel.Position = [141 6 400 330];

            % Create PlotScaleDropDownLabel
            app.PlotScaleDropDownLabel = uilabel(app.Panel);
            app.PlotScaleDropDownLabel.HorizontalAlignment = 'right';
            app.PlotScaleDropDownLabel.Position = [3 297 60 22];
            app.PlotScaleDropDownLabel.Text = 'Plot Scale';

            % Create PlotScaleDropDown
            app.PlotScaleDropDown = uidropdown(app.Panel);
            app.PlotScaleDropDown.Items = {'Linear', 'Log', 'Negative Log10'};
            app.PlotScaleDropDown.ItemsData = {'nla.ProbPlotMethod.DEFAULT', 'nla.ProbPlotMethod.LOG', 'nla.ProbPlotMethod.NEGATIVE_LOG_10'};
            app.PlotScaleDropDown.ValueChangedFcn = createCallbackFcn(app, @PlotScaleValueChanged, true);
            app.PlotScaleDropDown.Position = [78 297 100 22];
            app.PlotScaleDropDown.Value = 'nla.ProbPlotMethod.DEFAULT';

            % Create RankingDropDownLabel
            app.RankingDropDownLabel = uilabel(app.Panel);
            app.RankingDropDownLabel.HorizontalAlignment = 'right';
            app.RankingDropDownLabel.Position = [226 297 50 22];
            app.RankingDropDownLabel.Text = 'Ranking';

            % Create RankingDropDown
            app.RankingDropDown = uidropdown(app.Panel);
            app.RankingDropDown.Items = {'Uncorrected', 'Winkler', 'Westfall-Young'};
            app.RankingDropDown.ItemsData = {'nla.RankingMethod.UNCORRECTED', 'nla.RankingMethod.WINKLER', 'nla.RankingMethod.WESTFALL_YOUNG'};
            app.RankingDropDown.Position = [291 297 100 22];
            app.RankingDropDown.Value = 'nla.RankingMethod.UNCORRECTED';

            % Create UpperLimitEditFieldLabel
            app.UpperLimitEditFieldLabel = uilabel(app.Panel);
            app.UpperLimitEditFieldLabel.HorizontalAlignment = 'right';
            app.UpperLimitEditFieldLabel.Position = [46 267 70 22];
            app.UpperLimitEditFieldLabel.Text = 'Upper Limit';

            % Create UpperLimitEditField
            app.UpperLimitEditField = uieditfield(app.Panel, 'numeric');
            app.UpperLimitEditField.ValueChangedFcn = createCallbackFcn(app, @PlotScaleValueChanged, true);
            app.UpperLimitEditField.Position = [126 267 52 22];
            app.UpperLimitEditField.Value = 0.05;

            % Create LowerLimitEditFieldLabel
            app.LowerLimitEditFieldLabel = uilabel(app.Panel);
            app.LowerLimitEditFieldLabel.HorizontalAlignment = 'right';
            app.LowerLimitEditFieldLabel.Position = [259 267 70 22];
            app.LowerLimitEditFieldLabel.Text = 'Lower Limit';

            % Create LowerLimitEditField
            app.LowerLimitEditField = uieditfield(app.Panel, 'numeric');
            app.LowerLimitEditField.ValueChangedFcn = createCallbackFcn(app, @PlotScaleValueChanged, true);
            app.LowerLimitEditField.Position = [339 267 52 22];

            % Create pvalueThresholdEditFieldLabel
            app.pvalueThresholdEditFieldLabel = uilabel(app.Panel);
            app.pvalueThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.pvalueThresholdEditFieldLabel.Position = [14 237 102 22];
            app.pvalueThresholdEditFieldLabel.Text = 'p-value Threshold';

            % Create pvalueThresholdEditField
            app.pvalueThresholdEditField = uieditfield(app.Panel, 'numeric');
            app.pvalueThresholdEditField.ValueChangedFcn = createCallbackFcn(app, @pvalueThresholdEditFieldValueChanged, true);
            app.pvalueThresholdEditField.Position = [126 237 52 22];
            app.pvalueThresholdEditField.Value = 0.05;

            % Create CohensDThresholdEditFieldLabel
            app.CohensDThresholdEditFieldLabel = uilabel(app.Panel);
            app.CohensDThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.CohensDThresholdEditFieldLabel.Position = [195 237 118 22];
            app.CohensDThresholdEditFieldLabel.Text = 'Cohen''s D Threshold';

            % Create CohensDThresholdEditField
            app.CohensDThresholdEditField = uieditfield(app.Panel, 'numeric');
            app.CohensDThresholdEditField.Position = [339 237 52 22];
            app.CohensDThresholdEditField.Value = 0.5;

            % Create ColormapDropDownLabel
            app.ColormapDropDownLabel = uilabel(app.Panel);
            app.ColormapDropDownLabel.HorizontalAlignment = 'right';
            app.ColormapDropDownLabel.Position = [9 177 58 22];
            app.ColormapDropDownLabel.Text = 'Colormap';

            % Create ColormapDropDown
            app.ColormapDropDown = uidropdown(app.Panel);
            app.ColormapDropDown.Items = {};
            app.ColormapDropDown.ValueChangedFcn = createCallbackFcn(app, @PlotScaleValueChanged, true);
            app.ColormapDropDown.Position = [78 177 100 22];
            app.ColormapDropDown.Value = {};

            % Create LegendVisibleDropDownLabel
            app.LegendVisibleDropDownLabel = uilabel(app.Panel);
            app.LegendVisibleDropDownLabel.HorizontalAlignment = 'right';
            app.LegendVisibleDropDownLabel.Position = [233 177 84 22];
            app.LegendVisibleDropDownLabel.Text = 'Legend Visible';

            % Create LegendVisibleDropDown
            app.LegendVisibleDropDown = uidropdown(app.Panel);
            app.LegendVisibleDropDown.Items = {'On', 'Off'};
            app.LegendVisibleDropDown.Position = [332 177 59 22];
            app.LegendVisibleDropDown.Value = 'On';

            % Create MultipleComparisonCorrectionDropDownLabel
            app.MultipleComparisonCorrectionDropDownLabel = uilabel(app.Panel);
            app.MultipleComparisonCorrectionDropDownLabel.HorizontalAlignment = 'right';
            app.MultipleComparisonCorrectionDropDownLabel.Position = [11 147 178 22];
            app.MultipleComparisonCorrectionDropDownLabel.Text = 'Multiple Comparison Correction';

            % Create MultipleComparisonCorrectionDropDown
            app.MultipleComparisonCorrectionDropDown = uidropdown(app.Panel);
            app.MultipleComparisonCorrectionDropDown.Items = {'None', 'Bonferroni', 'Benjamini-Hochberg', 'Benjamini-Yekutieli'};
            app.MultipleComparisonCorrectionDropDown.ValueChangedFcn = createCallbackFcn(app, @PlotScaleValueChanged, true);
            app.MultipleComparisonCorrectionDropDown.Position = [226 147 165 22];
            app.MultipleComparisonCorrectionDropDown.Value = 'None';

            % Create CohensDThresholdCheckBox
            app.CohensDThresholdCheckBox = uicheckbox(app.Panel);
            app.CohensDThresholdCheckBox.Text = 'Cohen''s D Threshold';
            app.CohensDThresholdCheckBox.Position = [257 207 134 22];
            app.CohensDThresholdCheckBox.Value = true;

            % Create ROIcentroidsonbrainplotsCheckBox
            app.ROIcentroidsonbrainplotsCheckBox = uicheckbox(app.Panel);
            app.ROIcentroidsonbrainplotsCheckBox.ValueChangedFcn = createCallbackFcn(app, @ROIcentroidsonbrainplotsCheckBoxValueChanged, true);
            app.ROIcentroidsonbrainplotsCheckBox.Text = 'ROI centroids on brain plots';
            app.ROIcentroidsonbrainplotsCheckBox.Position = [7 207 171 22];

            % Create ViewChordPlotsButton
            app.ViewChordPlotsButton = uibutton(app.Panel, 'push');
            app.ViewChordPlotsButton.ButtonPushedFcn = createCallbackFcn(app, @ViewChordPlotsButtonPushed, true);
            app.ViewChordPlotsButton.Position = [71 117 107 22];
            app.ViewChordPlotsButton.Text = 'View Chord Plots';

            % Create ViewEdgeChordPlotsButton
            app.ViewEdgeChordPlotsButton = uibutton(app.Panel, 'push');
            app.ViewEdgeChordPlotsButton.ButtonPushedFcn = createCallbackFcn(app, @ViewEdgeChordPlotsButtonPushed, true);
            app.ViewEdgeChordPlotsButton.Position = [252 117 139 22];
            app.ViewEdgeChordPlotsButton.Text = 'View Edge Chord Plots';

            % Create EdgeChordPlotTypeDropDownLabel
            app.EdgeChordPlotTypeDropDownLabel = uilabel(app.Panel);
            app.EdgeChordPlotTypeDropDownLabel.HorizontalAlignment = 'right';
            app.EdgeChordPlotTypeDropDownLabel.Position = [71 87 123 22];
            app.EdgeChordPlotTypeDropDownLabel.Text = 'Edge Chord Plot Type';

            % Create EdgeChordPlotTypeDropDown
            app.EdgeChordPlotTypeDropDown = uidropdown(app.Panel);
            app.EdgeChordPlotTypeDropDown.Items = {};
            app.EdgeChordPlotTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @EdgeChordPlotTypeDropDownValueChanged, true);
            app.EdgeChordPlotTypeDropDown.Position = [226 87 165 22];
            app.EdgeChordPlotTypeDropDown.Value = {};

            % Create ViewConvergenceMapButton
            app.ViewConvergenceMapButton = uibutton(app.Panel, 'push');
            app.ViewConvergenceMapButton.ButtonPushedFcn = createCallbackFcn(app, @ViewConvergenceMapButtonPushed, true);
            app.ViewConvergenceMapButton.Position = [11 57 143 22];
            app.ViewConvergenceMapButton.Text = 'View Convergence Map';

            % Create ConvergencePlotColorDropDownLabel
            app.ConvergencePlotColorDropDownLabel = uilabel(app.Panel);
            app.ConvergencePlotColorDropDownLabel.HorizontalAlignment = 'right';
            app.ConvergencePlotColorDropDownLabel.Position = [161 57 133 22];
            app.ConvergencePlotColorDropDownLabel.Text = 'Convergence Plot Color';

            % Create ConvergencePlotColorDropDown
            app.ConvergencePlotColorDropDown = uidropdown(app.Panel);
            app.ConvergencePlotColorDropDown.Items = {'Bone', 'Winter', 'Autumn', 'Copper'};
            app.ConvergencePlotColorDropDown.Position = [309 57 82 22];
            app.ConvergencePlotColorDropDown.Value = 'Autumn';

            % Create ApplyButton
            app.ApplyButton = uibutton(app.Panel, 'push');
            app.ApplyButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyButtonPushed, true);
            app.ApplyButton.Position = [21 27 100 22];
            app.ApplyButton.Text = 'Apply';

            % Create Panel_2
            app.Panel_2 = uipanel(app.UIFigure);
            app.Panel_2.AutoResizeChildren = 'off';
            app.Panel_2.BackgroundColor = [1 1 1];
            app.Panel_2.Position = [86 346 510 480];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = NetworkTestPlotApp(varargin)

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