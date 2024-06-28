classdef NetworkTestPlot < handle

    properties
        network_atlas
        network_test_result
        test_method
        edge_test_options
        network_test_options
        x_position
        y_position
        plot_figure = false
        options_panel = false
        matrix_plot = false
        height = 800
        panel_height = 300
        current_settings = struct()
        parameters
    end

    properties (Dependent)
        is_noncorrelation_input
    end

    properties (Constant)
        WIDTH = 500
        colormap_choices = ["Parula", "Turbo", "HSV", "Hot", "Cool", "Spring", "Summer", "Autumn", "Winter", "Gray",...
            "Bone", "Copper", "Pink"]; % Colorbar choices
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
            "convergence_color", "convergence"...
        )
    end

    methods

        function obj = NetworkTestPlot(network_test_result, network_atlas, test_method, edge_test_options, network_test_options, varargin)
            
            test_plot_parser = inputParser;
            addRequired(test_plot_parser, "network_test_result");
            addRequired(test_plot_parser, "network_atlas");
            addRequired(test_plot_parser, "test_method");
            addRequired(test_plot_parser, "edge_test_options");
            addRequired(test_plot_parser, "network_test_options");

            validNumberInput = @(x) isnumeric(x) && isscalar(x);
            addParameter(test_plot_parser, "x_position", 300, validNumberInput);
            addParameter(test_plot_parser, "y_position", 0, validNumberInput);
        
            parse(test_plot_parser, network_test_result, network_atlas, test_method, edge_test_options, network_test_options, varargin{:});
            properties = {"network_test_result", "network_atlas", "test_method", "edge_test_options", "network_test_options", "x_position", "y_position"};
            for property = properties
                obj.(property{1}) = test_plot_parser.Results.(property{1});
            end
        end

        function p_value = choosePlottingMethod(obj)
            
            p_value = "p_value";
            if obj.edge_test_options == nla.gfx.ProbPlotMethod.STATISTIC
                p_value = strcat("statistic_", p_value);
            end
            if ~obj.network_test_result.is_noncorrelation_input && obj.test_method == "within_network_pair"
                p_value = strcat("single_sample_", p_value);
            end
        end

        function title = getPlotTitle(obj)

            switch obj.test_method
                case "no_permutations"
                    title = sprintf("Non-permuted Method\nNon-permuted Significance");
                case "full_connectome"
                    title = sprintf("Full Connectome Method\nNetwork vs. Connectome Significance");
                case "within_network_pair"
                    title = sprintf("Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair");
                case "winkler_method"
                    title = sprintf("Winkler Method");
                case "westfall_young"
                    title = sprintf("Westfall-Young ranking");
            end
        end

        function drawFigure(obj, edge_test_result)

            obj.plot_figure = uifigure();
            obj.plot_figure.Position = [obj.plot_figure.Position(1), obj.plot_figure.Position(2), obj.WIDTH, obj.height];
            obj.options_panel = uipanel(obj.plot_figure, "Units", "pixels", "Position", [10, 10, 480, obj.panel_height]);
            % obj.drawOptions()
            % obj.drawTriMatrixPlot(edge_test_result);
        end

        function drawTriMatrixPlot(obj, edge_test_result)

            plot_data = obj.network_test_result.(obj.test_method).(obj.choosePlottingMethod());

            obj.parameters = nla.net.result.NetworkResultPlotParameter(obj.network_test_result, obj.network_atlas,...
                obj.network_test_options);
            probability_parameters = obj.parameters.plotProbabilityParameters(obj.edge_test_options, edge_test_result,...
                obj.test_method, "p_value", "", obj.current_settings.mcc, obj.createSignificanceFilter());

            plotter = nla.net.result.plot.PermutationTestPlotter(obj.network_atlas);
            plotter.plotProbability(obj.plot_figure, probability_parameters, nla.inputField.LABEL_GAP, obj.y_position + 300);
        end

        function cohens_d_filter = createSignificanceFilter(obj)
            cohens_d_filter = nla.TriMatrix(obj.network_atlas.numNets, "logical", nla.TriMatrixDiag.KEEP_DIAGONAL);
            if ~isequal(obj.network_test_result.full_connectome, false)
                cohens_d_filter.v = (obj.network_test_result.full_connectome.d.v >= obj.network_test_options.d_max);
            end
            if ~isequal(obj.network_test_result.within_network_pair, false) && isfield(obj.network_test_result.within_network_pair, "d")
                cohens_d_filter.v = (obj.network_test_result.within_network_pair.d.v >= obj.network_test_options.d_max);
            end
        end

        function drawOptions(obj)
            import nla.inputField.LABEL_GAP nla.inputField.LABEL_H nla.inputField.PullDown nla.inputField.CheckBox
            import nla.inputField.Button nla.inputField.Number

            % All the options (buttons, pulldowns, checkboxes)
            scale_option = PullDown("plot_scale", "Plot Scale", ["Linear", "Log", "Negative Log10"]);
            ranking_method = PullDown("ranking", "Ranking", ["Eggebrecht", "Winkler", "Westfall-Young"]);
            cohens_d = CheckBox("cohens_d", "Cohen's D Threshold", false);
            centroids = CheckBox("centroids", "ROI Centroids in brain plots", false);
            multiple_comparison_correction = PullDown("mcc", "Multiple Comparison Correction",...
                ["None", "Bonferonni", "Benjamini-Hochberg", "Benjamini-Yekutieli"]);
            network_chord_plot = Button("network_chord", "View Chord Plots");
            edge_chord_plot = Button("edge_chord", "View Edge Chord Plots");
            convergence_plot = Button("convergence", "View Convergence Map");
            convergence_color = PullDown("convergence_color", "Convergence Plot Color",...
                ["Bone", "Winter", "Autumn", "Copper"]);
            apply = Button("apply", "Apply");
            upper_limit_box = Number("upper_limit", "Upper Limit", -Inf, 0.3, Inf);
            lower_limit_box = Number("lower_limit", "Lower Limit", -Inf, -0.3, Inf);
            colormap_choice = PullDown("colormap_choice", "Colormap", obj.colormap_choices);

            % Draw the options
            options = {...
                {scale_option, ranking_method},...
                {upper_limit_box, lower_limit_box},...
                {colormap_choice},...
                {multiple_comparison_correction},...
                {cohens_d, centroids},...
                {network_chord_plot, edge_chord_plot},...
                {convergence_plot, convergence_color},...
                {apply},...
            };
        
            settings = {scale_option, ranking_method, cohens_d, centroids, multiple_comparison_correction,...
                convergence_color, upper_limit_box, lower_limit_box, colormap_choice};
        
            y = obj.panel_height - LABEL_GAP;
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
                y = y - LABEL_GAP - LABEL_H;
                x = LABEL_GAP;
            end
            
            apply.field.ButtonPushedFcn = {@obj.applyChanges, settings};
        end

        %% getters for dependent props
        function value = get.is_noncorrelation_input(obj)
            value = obj.network_test_result.is_noncorrelation_input;
        end
        %%
    end

    methods (Access = protected)
        function applyChanges(obj, ~, ~, values)
            changes = {};
            for value = values;
                if isa(value{1}.field, "matlab.ui.control.Button")
                    setting_value = value{1}.field.Enable;
                else
                    setting_value = value{1}.field.Value;
                end
                if ~isequal(setting_value, obj.current_settings.(value{1}.name))
                    changes = [changes, value{1}.name];
                    obj.current_settings.(value{1}.name) = setting_value;
                end
            end
            
        end
    end
end