classdef NetworkTestPlot < handle

    properties
        network_atlas
        network_test_result
        ranking_method
        x_position
        y_position
        plot_figure = false
        options_panel = false
        matrix_plot = false
        height = 800
        panel_height = 300
    end

    properties (Dependent)
        is_noncorrelation_input
    end

    properties (Constant)
        WIDTH = 500
    end

    methods

        function obj = NetworkTestPlot(network_test_result, network_atlas, ranking_method, varargin)
            
            test_plot_parser = inputParser;
            addRequired(test_plot_parser, 'network_test_result');
            addRequired(test_plot_parser, 'network_atlas');
            addRequired(test_plot_parser, 'ranking_method');

            validNumberInput = @(x) isnumeric(x) && isscalar(x);
            addParameter(test_plot_parser, 'x_position', 300, validNumberInput);
            addParameter(test_plot_parser, 'y_position', 0, validNumberInput);
        
            parse(test_plot_parser, network_test_result, network_atlas, ranking_method, varargin{:});
            properties = {'network_test_result', 'network_atlas', 'ranking_method', 'x_position', 'y_position'};
            for property = properties
                obj.(property{1}) = test_plot_parser.Results.(property{1});
            end
        end

        function value = get.is_noncorrelation_input(obj)
            value = obj.network_test_result.is_noncorrelation_input;
        end


        function p_value = choosePlottingMethod(obj, test_options)
            
            p_value = "p_value";
            if test_options == nla.gfx.ProbPlotMethod.STATISTIC
                p_value = strcat("statistic_", p_value);
            end
            if ~obj.network_test_result.is_noncorrelation_input && obj.ranking_method == "within_network_pair"
                p_value = strcat("single_sample_", p_value);
            end
        end

        function title = getPlotTitle(obj, test_options)

            switch obj.ranking_method
                case "no_permutations"
                    title = sprintf("Non-permuted Method\nNon-permuted Significance");
                case "full_connectome"
                    title = sprintf("Full Connectome Method\nNetwork vs. Connectome Significance");
                case "within_network_pair"
                    title = sprintf("Within Network Pair Method\nNetwork Pair vs. Permuted Network Pair");
            end
        end

        function drawFigure(obj)

            obj.plot_figure = uifigure();
            obj.plot_figure.Position = [obj.plot_figure.Position(1), obj.plot_figure.Position(2), obj.WIDTH, obj.height];
            obj.options_panel = uipanel(obj.plot_figure, 'Units', 'pixels', 'Position', [10, 10, 480, obj.panel_height]);
        end

        function drawTriMatrixPlot(obj, test_options, network_test_options)

            plot_data = obj.network_test_result.(obj.ranking_method).(obj.choosePlottingMethod(test_options))
            obj.matrix_plot = nla.gfx.plots.MatrixPlot(obj.plot_figure, obj.getPlotTitle(test_options), plot_data, obj.network_atlas.nets, nla.gfx.FigSize.SMALL, 'y_position', obj.y_position + 300);
        end

        function drawOptions(obj, test_options, network_test_options)
            import nla.inputField.LABEL_GAP nla.inputField.LABEL_H nla.inputField.PullDown nla.inputField.CheckBox
            import nla.inputField.Button nla.inputField.Number

            % All the options (buttons, pulldowns, checkboxes)
            scale_option = PullDown("plot_scale", "Plot Scale", ["Linear", "Log", "Negative Log10"]);
            ranking_method = PullDown("ranking", "Ranking", ["No Permutation", "Full Connectome", "Within Network Pair", "Winkler/randomise", "Westfall-Young"]);
            cohens_d = CheckBox("cohens_d", "Cohen's D Threshold", false);
            centroids = CheckBox("centroids", "ROI Centroids in brain plots", false);
            multiple_comparison_correction = PullDown("mcc", "Multiple Comparison Correction", ["None", "Bonferonni", "Benjamini-Hochberg", "Benjamini-Yekutieli"]);
            network_chord_plot = Button("network_chord", "View Chord Plots");
            edge_chord_plot = Button("edge_chord", "View Edge Chord Plots");
            convergence_plot = Button("convergence", "View Convergence Map");
            convergence_color = PullDown("convergence_color", "Convergence Plot Color", ["Bone", "Winter", "Autumn", "Copper"]);
            apply = Button("apply", "Apply");
            upper_limit_box = Number("upper_limit", "Upper Limit", -Inf, 0.3, Inf);
            lower_limit_box = Number("lower_limit", "Lower Limit", -Inf, -0.3, Inf);

            
            % Draw the options
            options = {...
                {scale_option, ranking_method},...
                {upper_limit_box, lower_limit_box},...
                {multiple_comparison_correction},...
                {color_map_select},...
                {cohens_d, centroids},...
                {network_chord_plot, edge_chord_plot},...
                {convergence_plot, convergence_color},...
                {apply},...
            };
        
            y = obj.panel_height - LABEL_GAP;
            x = LABEL_GAP;
            for row = options
                for column = row{1}
                    [x_component, ~] = column{1}.draw(x, y, obj.options_panel, obj.plot_figure);
                    x = x + LABEL_GAP + x_component;
                end
                y = y - LABEL_GAP - LABEL_H;
                x = LABEL_GAP;
            end
                        
            apply.field.ButtonPushedFcn = @(~, ~)obj.applyChanges(~, ~, ~);

        end
    end

    methods (Access = protected)
        function applyChanges(obj, ~, ~, values)

        end

        function drawColorMapChoices(obj)
            import nla.gfx.plots.MatrixPlot

            COLORMAP_SAMPLE_COLORS = 16;
            colormap_choices = MatrixPlot().colormap_choices;
            colormap_html = [];
            for colors = 1:numel(colormap_choices)
                colormap_function = str2func(strcat(strcat("@(x) ", lower(colormap_choices{colors}), "(x)")));
                CData = colormap_function(COLORMAP_SAMPLE_COLORS);
                new_html_start = "<HTML>";
                new_html = "";
                for color_iterator = COLORMAP_SAMPLE_COLORS:-1:1
                    hex_code = nla.gfx.rgb2hex([CData(color_iterator, 1), CData(color_iterator, 2),...
                        CData(color_iterator, 3)]);
                    new_html = [new_html '<FONT bgcolor="' hex_code ' "color="' hex_code '">__</FONT>'];
                end
                new_html_end = [new_html "</HTML>"];
                new_html = [new_html_start new_html new_html_end];
                colormap_html = [colormap_html; {new_html}];
            end
        end
    end
end