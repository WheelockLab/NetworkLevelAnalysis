classdef NetworkTestPlot < handle

    properties
        network_atlas
        network_test_result
        edge_test_result
        test_method
        edge_test_options
        network_test_options
        x_position
        y_position
        plot_figure = false
        options_panel = false
        matrix_plot = false
        height = 600
        panel_height = 250
        current_settings = struct()
        settings
        parameters
        title = ""
    end

    properties (Dependent)
        is_noncorrelation_input
    end

    properties (Constant)
        WIDTH = 500
        colormap_choices = ["Parula", "Turbo", "HSV", "Hot", "Cool", "Spring", "Summer", "Autumn", "Winter", "Gray",...
            "Bone", "Copper", "Pink"] % Colorbar choices
        legend_visible = ["On", "Off"]
        COLORMAP_SAMPLE_COLORS = 16
        changes_to_functions = struct(...
            "upper_limit", "scale",...
            "lower_limit", "scale",...
            "colormap_choice", "scale",...
            "plot_scale", "scale",...
            "ranking", "ranking",...
            "cohens_d", "parameters",...
            "centroids", "centroids",...
            "mcc", "parameters",...
            "convergence_color", "convergence",...
            "p_threshold", "parameters",...
            "d_threshold", "parameters",...
            "legend_visible", "legend"...
        )
    end

    methods

        function obj = NetworkTestPlot(network_test_result, edge_test_result, network_atlas, test_method,...
                edge_test_options, network_test_options, varargin)
            
            test_plot_parser = inputParser;
            addRequired(test_plot_parser, "network_test_result");
            addRequired(test_plot_parser, "edge_test_result");
            addRequired(test_plot_parser, "network_atlas");
            addRequired(test_plot_parser, "test_method");
            addRequired(test_plot_parser, "edge_test_options");
            addRequired(test_plot_parser, "network_test_options");

            validNumberInput = @(x) isnumeric(x) && isscalar(x);
            addParameter(test_plot_parser, "x_position", 300, validNumberInput);
            addParameter(test_plot_parser, "y_position", 0, validNumberInput);
        
            parse(test_plot_parser, network_test_result, edge_test_result, network_atlas, test_method, edge_test_options,...
                network_test_options, varargin{:});
            properties = ["network_test_result", "edge_test_result", "network_atlas", "test_method", "edge_test_options",...
                "network_test_options", "x_position", "y_position"];
            for property = properties
                obj.(property{1}) = test_plot_parser.Results.(property{1});
            end
        end

        function getPlotTitle(obj)
            import nla.NetworkLevelMethod
            
            obj.title = "";
            % Building the plot title by going through options
            switch obj.test_method
                case "no_permutations"
                    obj.title = "Non-permuted Method\nNon-permuted Significance";
                case "full_connectome"
                    obj.title = "Full Connectome Method\nNetwork vs. Connectome Significance";
                case "within_network_pair"
                    obj.title = "Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair";
            end
            if isequal(obj.current_settings.cohens_d, true)
                obj.title = sprintf("%s (D > %g)", obj.title, obj.network_test_options.d_max);
            end
            if ~isequal(obj.test_method, "no_permutations")
                if isequal(obj.current_settings.ranking, nla.RankingMethod.WINKLER) 
                    obj.title = strcat(obj.title, "\nRanking by Winkler Method");
                elseif isequal(obj.current_settings.ranking, nla.RankingMethod.WESTFALL_YOUNG)
                    obj.title = strcat(obj.title, "\nRanking by Westfall-Young Method");
                else
                    obj.title = strcat(obj.title, "\nRanking by Eggebrecht Method");
                end
            end
        end

        function drawFigure(obj, plot_type)
            import nla.inputField.LABEL_GAP

            obj.plot_figure = uifigure("Color", "w");
            obj.plot_figure.Position = [obj.plot_figure.Position(1), obj.plot_figure.Position(2), obj.WIDTH,...
                obj.panel_height + (4 * LABEL_GAP)];
            obj.options_panel = uipanel(obj.plot_figure, "Units", "pixels", "Position", [10, 10, 480, obj.panel_height],...
                "BackgroundColor", "w");
            obj.drawOptions();
            % obj.resizeOptions();

            obj.parameters = nla.net.result.NetworkResultPlotParameter(obj.network_test_result, obj.network_atlas,...
                obj.network_test_options);
            
            [width, plot_height] = obj.drawTriMatrixPlot();
            if ~isequal(plot_type, nla.PlotType.FIGURE)
                obj.drawChord(plot_type);
            end


            obj.resizeFigure(width, plot_height);
        end

        function [width, height] = drawTriMatrixPlot(obj)
            import nla.net.result.NetworkTestResult         

            if ~isequal(obj.matrix_plot, false)
               obj.matrix_plot.plot_title.String = {};
               obj.parameters.updated_test_options.prob_max = obj.current_settings.p_threshold;
            end
            obj.getPlotTitle();

            switch obj.current_settings.mcc
                case "Benjamini-Hochberg"
                    mcc = "BenjaminiHochberg";
                case "Benjamini-Yekutieli"
                    mcc = "BenjaminiYekutieli";
                otherwise
                    mcc = obj.current_settings.mcc;
            end

            probability = NetworkTestResult().getPValueNames(obj.test_method, obj.network_test_result.test_name);

            probability_parameters = obj.parameters.plotProbabilityParameters(obj.edge_test_options, obj.edge_test_result,...
                obj.test_method, probability, sprintf(obj.title), mcc, obj.createSignificanceFilter(),...
                obj.current_settings.ranking);

            if obj.current_settings.upper_limit ~= 0.3 && obj.current_settings.lower_limit ~= -0.3
                probability_parameters.p_value_plot_max = obj.current_settings.upper_limit;
            end
            
            plotter = nla.net.result.plot.PermutationTestPlotter(obj.network_atlas);
            [width, height, obj.matrix_plot] = plotter.plotProbability(obj.plot_figure, probability_parameters,...
                nla.inputField.LABEL_GAP, obj.y_position + obj.panel_height);
            
            if probability_parameters.p_value_plot_max > 0
                obj.settings{7}.field.Value = str2double(obj.matrix_plot.color_bar.TickLabels{end});
                obj.settings{8}.field.Value = str2double(obj.matrix_plot.color_bar.TickLabels{1});
                obj.current_settings.upper_limit = str2double(obj.matrix_plot.color_bar.TickLabels{end});
                obj.current_settings.lower_limit = str2double(obj.matrix_plot.color_bar.TickLabels{1});
            else
                obj.settings{7}.field.Value = 0;
                obj.settings{8}.field.Value = 0;
                obj.current_settings.upper_limit = 0;
                obj.current_settings.lower_limit = 0;
            end
        end

        function drawChord(obj, ~, ~, plot_type)
            import nla.gfx.EdgeChordPlotMethod

            obj.getPlotTitle();

            probability = NetworkTestResult().getPValueNames(obj.test_method, obj.network_test_result.test_name);
            p_value = strcat("uncorrected_", probability);

            probability_parameters = obj.parameters.plotProbabilityParameters(obj.edge_test_options, obj.edge_test_result,...
                obj.test_method, p_value, sprintf(obj.title), obj.current_settings.mcc, obj.createSignificanceFilter(),...
                obj.current_settings.ranking);
            
            chord_plotter = nla.net.result.chord.ChordPlotter(obj.network_atlas, obj.edge_test_result);

            for setting = obj.settings
                if setting{1}.name == "edge_type"
                    method = setting{1}.field.Value;
                    probability_parameters.edge_chord_plot_method = method;
                    break
                end
            end
            chord_plotter.generateChordFigure(probability_parameters, plot_type);
            
        end

        function resizeFigure(obj, plot_width, plot_height)
            % This resizes automatically so that all the elements fit nicely inside. This is not for manually resizing the window
            import nla.inputField.LABEL_GAP

            current_width = obj.plot_figure.Position(3);
            current_height = obj.plot_figure.Position(4);

            if ~isequal(current_width, plot_width + (2 * LABEL_GAP))
                obj.plot_figure.Position(3) = plot_width + (2 * LABEL_GAP);
                obj.options_panel.Position(1) = ((obj.plot_figure.Position(3) - obj.options_panel.Position(3)) / 2);
            end

            if ~isequal(current_height, (2 * LABEL_GAP) + obj.plot_figure.Position(4) + plot_height)
                obj.plot_figure.Position(4) = (2 * LABEL_GAP) + current_height + plot_height;
            end
        end

        function cohens_d_filter = createSignificanceFilter(obj)
            import nla.NetworkLevelMethod

            % This is for using Cohen's D
            cohens_d_filter = nla.TriMatrix(obj.network_atlas.numNets, "logical", nla.TriMatrixDiag.KEEP_DIAGONAL);
            if isequal(obj.current_settings.cohens_d, true)
                if isequal(obj.test_method, "no_permutations") && ~isequal(obj.network_test_result.no_permutations, false)
                    cohens_d_filter.v = (obj.network_test_result.no_permutations.d.v >= obj.network_test_options.d_max);
                end 
                if isequal(obj.test_method, "full_connectome") && ~isequal(obj.network_test_result.full_connectome, false)
                    cohens_d_filter.v = (obj.network_test_result.full_connectome.d.v >= obj.network_test_options.d_max);
                end
                if ~isequal(obj.network_test_result.within_network_pair, false) && isfield(obj.network_test_result.within_network_pair, "d")...
                    && ~isequal(obj.test_method, "full_connectome")
                    cohens_d_filter.v = (obj.network_test_result.within_network_pair.d.v >= obj.network_test_options.d_max);
                end
            else
                cohens_d_filter.v = true(numel(cohens_d_filter.v), 1);
            end
        end

        function [width, height] = drawOptions(obj)
            import nla.inputField.LABEL_GAP nla.inputField.LABEL_H nla.inputField.PullDown nla.inputField.CheckBox
            import nla.inputField.Button nla.inputField.Number nla.NetworkLevelMethod nla.RankingMethod
            import nla.gfx.EdgeChordPlotMethod nla.gfx.ProbPlotMethod

            % All the options (buttons, pulldowns, checkboxes)
            scale_option = PullDown("plot_scale", "Plot Scale", ["Linear", "Log", "Negative Log10"],...
                [ProbPlotMethod.DEFAULT, ProbPlotMethod.LOG, ProbPlotMethod.NEGATIVE_LOG_10]);
            ranking_method = PullDown("ranking", "Ranking", ["Eggebrecht", "Winkler", "Westfall-Young"],...
                [RankingMethod.EGGEBRECHT, RankingMethod.WINKLER, RankingMethod.WESTFALL_YOUNG]);
            cohens_d = CheckBox("cohens_d", "Cohen's D Threshold", true);
            centroids = CheckBox("centroids", "ROI Centroids in brain plots", false);
            multiple_comparison_correction = PullDown("mcc", "Multiple Comparison Correction",...
                ["None", "Bonferroni", "Benjamini-Hochberg", "Benjamini-Yekutieli"]);
            network_chord_plot = Button("network_chord", "View Chord Plots", {@obj.drawChord, nla.PlotType.CHORD});
            edge_chord_type = PullDown(...
                "edge_type", "Edge-level Chord Type",...
                ["p-value", "Coefficient", "Coefficient (Split)", "Coefficient (Basic)", "Coefficient (Baseic, Split)"],...
                [EdgeChordPlotMethod.PROB, EdgeChordPlotMethod.COEFF, EdgeChordPlotMethod.COEFF_SPLIT, EdgeChordPlotMethod.COEFF_BASE, EdgeChordPlotMethod.COEFF_BASE_SPLIT]...
            );
            edge_chord_plot = Button("edge_chord", "View Edge Chord Plots", {@obj.drawChord, nla.PlotType.CHORD_EDGE});
            convergence_plot = Button("convergence", "View Convergence Map", @obj.openConvergencePlot);
            convergence_color = PullDown("convergence_color", "Convergence Plot Color",...
                ["Bone", "Winter", "Autumn", "Copper"]);
            apply = Button("apply", "Apply");
            upper_limit_box = Number("upper_limit", "Upper Limit", -Inf, 0.3, Inf);
            lower_limit_box = Number("lower_limit", "Lower Limit", -Inf, -0.3, Inf);
            colormap_choice = PullDown("colormap_choice", "Colormap", obj.colormap_choices);
            legend_visible = PullDown("legend_visible", "Legend Visible", obj.legend_visible);
            p_value_threshold = Number("p_threshold", "p-value Threshold", -Inf, 0.05, Inf);
            cohens_d_threshold = Number("d_threshold", "Cohen's D Threshold", -Inf, 0.5, Inf);

            % Draw the options
            options = {...
                {apply},...
                {convergence_plot, convergence_color},...
                {edge_chord_type},...
                {network_chord_plot, edge_chord_plot},...
                {cohens_d, centroids},...
                {multiple_comparison_correction},...
                {colormap_choice, legend_visible},...
                {p_value_threshold, cohens_d_threshold},...
                {upper_limit_box, lower_limit_box},...
                {scale_option, ranking_method}...
            };
        
            obj.settings = {scale_option, ranking_method, cohens_d, centroids, multiple_comparison_correction,...
                convergence_color, upper_limit_box, lower_limit_box, colormap_choice, legend_visible,...
                edge_chord_type, p_value_threshold, cohens_d_threshold};
        
            y = LABEL_GAP;
            x = LABEL_GAP;
            for row = options
                for column = row{1}
                    [x_component, ~] = column{1}.draw(x, y, obj.options_panel, obj.plot_figure);
                    x = x + LABEL_GAP + x_component;
                    if ~isequal(column{1}.name, "apply") 
                        if isa(column{1}.field, "matlab.ui.control.Button")
                            obj.current_settings.(column{1}.name) = column{1}.field.Enable;
                        else
                            obj.current_settings.(column{1}.name) = column{1}.field.Value;
                        end
                    end
                end
                y = y + LABEL_GAP + LABEL_H;
                x = LABEL_GAP;
            end
            
            if y > obj.panel_height
                obj.options_panel.Position(4) = y + LABEL_GAP;
                height_difference = y - obj.panel_height;
                for row = options
                    for column = row{1}
                        column{1}.field.Position(2) = column{1}.field.Position(2) + height_difference;
                        if isa(column{1}.label, "matlab.ui.control.Label")
                            column{1}.label.Position(2) = column{1}.label.Position(2) + height_difference;
                        end
                    end
                end
            end
            apply.field.ButtonPushedFcn = {@obj.applyChanges, obj.settings};
        end

        %% getters for dependent props
        function value = get.is_noncorrelation_input(obj)
            value = obj.network_test_result.is_noncorrelation_input;
        end
        %%
    end

    methods (Access = protected)
        function applyChanges(obj, ~, ~, values)
            % Choosing what is being updated. If we don't have to update the Trimatrix, we'll skip that
            progress_bar = uiprogressdlg(obj.plot_figure, "Title", "Please Wait", "Message", "Applying Changes...",...
                "Indeterminate", true);

            changes = {};
            for value = values
                if isa(value{1}.field, "matlab.ui.control.Button")
                    setting_value = value{1}.field.Enable;
                else
                    setting_value = value{1}.field.Value;
                end

                if ~isequal(setting_value, obj.current_settings.(value{1}.name))
                    changes = [changes, obj.changes_to_functions.(value{1}.name)];
                    obj.current_settings.(value{1}.name) = setting_value;
                end
            end

            if any(strcmp("parameters", changes)) || any(strcmp("ranking", changes))
                if isobject(obj.matrix_plot)
                    obj.matrix_plot.removeLegend();
                    delete(obj.matrix_plot.image_display);
                    delete(obj.matrix_plot.color_bar);
                end
                progress_bar.Message = "Redrawing TriMatrix...";
                obj.drawTriMatrixPlot();
            elseif any(strcmp("scale", changes))
                progress_bar.Message = "Changing scale of existing TriMatrix...";
                obj.matrix_plot.applyScale(false, false, obj.current_settings.upper_limit,...
                    obj.current_settings.lower_limit, obj.current_settings.plot_scale,...
                    obj.current_settings.colormap_choice);
                obj.settings{7}.field.Value = str2double(obj.matrix_plot.color_bar.TickLabels{end});
                obj.settings{8}.field.Value = str2double(obj.matrix_plot.color_bar.TickLabels{1});
            end
            if any(strcmp("legend", changes))
                if isobject(obj.matrix_plot.display_legend) && isequal(obj.current_settings.legend_visible, "Off")
                    obj.matrix_plot.display_legend.Visible = "off";
                else
                    obj.matrix_plot.display_legend.Visible = "on";
                end
            end
            close(progress_bar);
        end

        function openConvergencePlot(obj, ~, ~)
            import nla.NetworkLevelMethod
            
            flags = struct();
            flags.show_full_conn = false;
            flags.show_within_net_pair = false;
            flags.show_nonpermuted = false;
            switch obj.test_method
                case "no_permutations"
                    flags.show_nonpermuted = true;
                case "full_connectome"
                    flags.show_full_conn = true;
                case "within_network_pair"
                    flags.show_within_net_pair = true;
            end
            [test_number, significance_count_matrix, names] = obj.network_test_result.getSigMat(obj.network_test_options,...
                obj.network_atlas, flags);
            
                colors = str2func(lower(obj.current_settings.convergence_color));
            if isequal(obj.current_settings.convergence_color, "Bone")
                color_map = flip(colors());
            else
                color_map = [[1, 1, 1]; flip(colors())];
            end

            nla.gfx.drawConvergenceMap(obj.edge_test_options, obj.network_test_options, obj.network_atlas, significance_count_matrix,...
                test_number, names, obj.edge_test_result, color_map);
        end
    end
end