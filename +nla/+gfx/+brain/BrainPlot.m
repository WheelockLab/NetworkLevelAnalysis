classdef BrainPlot < handle

    properties
        plot_figure
        edge_test_options
        network_test_options
        network_atlas
        edge_test_result
        network1
        network2
        test_name
        upper_limit
        lower_limit
        color_map = cat(1, winter(1000), flip(autumn(1000)));
        color_map_axis
        color_bar
        ROI_values = []
        function_connectivity_values = []
        ROI_radius
        surface_parcels
        mesh_type
        mesh_alpha
        all_edges = []
    end

    properties (Constant)
        noncorrelation_input_tests = ["chi_squared", "hypergeometric"] % These are tests that do not use correlation coefficients as inputs
        default_settings = struct("upper_limit", 0.5, "lower_limit", -0.5)
    end

    properties (Dependent)
        is_noncorrelation_input
        functional_connectivity_exists
        color_functional_connectivity
    end

    methods

        function obj = BrainPlot(edge_test_result, edge_test_options, network_test_options, network1, network2, network_atlas, varargin)
            brain_input_parser = inputParser;
            addRequired(brain_input_parser, "edge_test_result");
            addRequired(brain_input_parser, "edge_test_options");
            addRequired(brain_input_parser, "network_test_options");
            addRequired(brain_input_parser, "network1");
            addRequired(brain_input_parser, "network2");
            addRequired(brain_input_parser, "network_atlas");

            validNumberInput = @(x) isnumeric(x) && isscalar(x);
            addParameter(brain_input_parser, "ROI_radius", 3, validNumberInput);
            addParameter(brain_input_parser, "surface_parcels", true, @isboolean);
            addParameter(brain_input_parser, "mesh_type", nla.gfx.MeshType.STD, @isenum);
            addParameter(brain_input_parser, "mesh_alpha", 0.25, validNumberInput);

            parse(brain_input_parser, edge_test_result, edge_test_options, network_test_options, network1, network2, network_atlas, varargin{:});
            properties = {"edge_test_result", "edge_test_options", "network_test_options", "network1", "network2", "network_atlas", "ROI_radius", "surface_parcels", "mesh_type", "mesh_alpha"};
            for property = properties
                obj.(property{1}) = brain_input_parser.Results.(property{1});
            end

            %%
            % everything below here we'll need, but we need other values set first. and they need to be editable
            obj.plot_figure = nla.gfx.createFigure(1550, 750);

            obj.upper_limit = obj.edge_test_result.coeff_range(2);
            obj.lower_limit = obj.edge_test_result.coeff_range(1);

            obj.ROI_values = nan(obj.network_atlas.numROIs(), 1);
            obj.function_connectivity_values = nan(obj.network_atlas.numROIs(), 1);
            %%
        end

        function drawBrainPlots(obj)
            import nla.gfx.ViewPos nla.gfx.BrainColorMode

            obj.setROIandConnectivity();
            
            if obj.surface_parcels && ~islogical(obj.network_atlas.parcels)
                edges1 = obj.singlePlot(subplot("Position", [0.45, 0.505, 0.53, 0.45]), ViewPos.LAT, BrainColorMode.COLOR_ROIS, obj.color_map);
                edges2 = obj.singlePlot(subplot("Position", [0.45, 0.055, 0.53, 0.45]), ViewPos.MED, BrainColorMode.COLOR_ROIS, obj.color_map);
                obj.all_edges = [edges1 edges2];
            else
                edges1 = obj.singlePlot(subplot("Position", [0.45, 0.505, 0.26, 0.45]), ViewPos.BACK, BrainColorMode.NONE, obj.color_map);
                edges2 = obj.singlePlot(subplot("Position", [0.73, 0.505, 0.26, 0.45]), ViewPos.FRONT, BrainColorMode.NONE, obj.color_map);
                edges3 = obj.singlePlot(subplot("Position", [0.45, 0.055, 0.26, 0.45]), ViewPos.LEFT, BrainColorMode.NONE, obj.color_map);
                edges4 = obj.singlePlot(subplot("Position", [0.73, 0.055, 0.26, 0.45]), ViewPos.RIGHT, BrainColorMode.NONE, obj.color_map);
                obj.all_edges = [edges1 edges2 edges3 edges4];
            end

            if obj.color_functional_connectivity
                plot_axis = subplot("Position", [0.075, 0.175, 0.35, 0.75]);
            else
                plot_axis = subplot("Position", [0.075, 0.025, 0.35, 0.85]);
            end

            if obj.surface_parcels && ~islogical(obj.network_atlas.parcels)
                edges5 = obj.singlePlot(plot_axis, ViewPos.DORSAL, BrainColorMode.COLOR_ROIS, obj.color_map);
            else
                edges5 = obj.singlePlot(plot_axis, ViewPos.DORSAL, BrainColorMode.NONE, obj.color_map);
            end
            obj.all_edges = [obj.all_edges edges5];

            light("Position", [0, 100, 100], "Style", "local");

            % Display Legend
            hold(plot_axis, "on");
            if obj.network1 == obj.network2
                legend_entry = bar(plot_axis, NaN);
                legend_entry.FaceColor = obj.network_atlas.nets(obj.network1).color;
                legend_entry.DisplayName = obj.network_atlas.nets(obj.network1).name;
            else
                for network = [obj.network1, obj.network2]
                    legend_entry = bar(plot_axis, NaN);
                    legend_entry.FaceColor = obj.network_atlas.nets(network).color;
                    legend_entry.DisplayName = obj.network_atlas.nets(network).name;
                end
            end
            hold(plot_axis, "off");
            nla.gfx.hideAxes(plot_axis);

            obj.drawColorMap(plot_axis);

            obj.color_map_axis = plot_axis;

            obj.addTitle();
        end

        function setROIandConnectivity(obj)

            network1_ROI_indexes = obj.network_atlas.nets(obj.network1).indexes;
            network2_ROI_indexes = obj.network_atlas.nets(obj.network2).indexes;

            for ROI_index1_iterator = 1:numel(network1_ROI_indexes)
                network1_ROI_index = network1_ROI_indexes(ROI_index1_iterator);
                [coefficient1, coefficient2, function_connectivity1, function_connectivity2] = obj.getCoefficients(network1_ROI_index, network2_ROI_indexes);
                obj.ROI_values(network1_ROI_index) = (sum(coefficient1) + sum(coefficient2)) / (numel(coefficient1) + numel(coefficient2));
                obj.function_connectivity_values(network1_ROI_index) = (sum(function_connectivity1) + sum(function_connectivity2)) / (numel(function_connectivity1) + numel(function_connectivity2));
            end

            for ROI_index2_iterator = 1:numel(network2_ROI_indexes)
                network2_ROI_index = network2_ROI_indexes(ROI_index2_iterator);
                [coefficient1, coefficient2, function_connectivity1, function_connectivity2] = obj.getCoefficients(network2_ROI_index, network1_ROI_indexes);
                ROI_value = (sum(coefficient1) + sum(coefficient2)) / (numel(coefficient1) + numel(coefficient2));
                function_connectivity_value = (sum(function_connectivity1) + sum(function_connectivity2)) / (numel(function_connectivity1) + numel(function_connectivity2));
                if obj.network1 == obj.network2
                    obj.ROI_values(network2_ROI_index) = (obj.ROI_values(network2_ROI_index) + ROI_value) ./ 2;
                    obj.function_connectivity_values(network2_ROI_index) = (obj.function_connectivity_values(network2_ROI_index) + function_connectivity_value) ./ 2;
                else
                    obj.ROI_values(network2_ROI_index) = ROI_value;
                    obj.function_connectivity_values(network2_ROI_index) = function_connectivity_value;
                end
            end
        end

        function [coefficient1, coefficient2, function_connectivity1, function_connectivity2] =...
            getCoefficients(obj, network1_index, network2_indexes)
            coefficient1 = obj.edge_test_result.coeff.get(network1_index, network2_indexes);
            coefficient2 = obj.edge_test_result.coeff.get(network2_indexes, network1_index);

            function_connectivity1 = false;
            function_connectivity2 = false;
            if obj.functional_connectivity_exists
                function_connectivity1 = mean(obj.edge_test_options.func_conn.get(network1_index, network2_indexes), 2);
                function_connectivity2 = mean(obj.edge_test_options.func_conn.get(network2_indexes, network1_index), 2);
            end

            if obj.is_noncorrelation_input
                probability_significance1 = obj.edge_test_result.prob_sig.get(network1_index, network2_indexes);
                probability_significance2 = obj.edge_test_result.prob_sig.get(network2_indexes, network1_index);

                coefficient1 = coefficient1(logical(probability_significance1));
                coefficient2 = coefficient2(logical(probability_significance2));
                function_connectivity1 = function_connectivity1(logical(probability_significance1));
                function_connectivity2 = function_connectivity2(logical(probability_significance2));
            end
        end

        function colors = mapColorsToLimits(obj, value, function_connectivity_average, varargin)
            import nla.gfx.valToColor

            if isempty(varargin)
                scale_min = -0.5;
                scale_max = 0.5;
            else
                scale_min = str2double(varargin{1});
                scale_max = str2double(varargin{2});
            end

            color_rows = size(obj.color_map);
            color_map_positive = obj.color_map(1:(color_rows/2), :);
            color_map_negative = obj.color_map(((color_rows/2) + 1):end, :);

            if obj.color_functional_connectivity
                colors_positive = valToColor(function_connectivity_average, scale_min, scale_max, color_map_positive);
                colors_negative = valToColor(function_connectivity_average, scale_min, scale_max, color_map_negative);
                colors(value > 0, :) = colors_positive(value > 0, :);
                colors(value <= 0, :) = colors_negative(value <= 0, :);
            else
                colors = valToColor(value, obj.lower_limit, obj.upper_limit, obj.color_map);
            end
            colors(isnan(value), :) = 0.5;
        end

        function edges = drawEdges(obj, ROI_position, plot_axis)

            point1_indexes = obj.network_atlas.nets(obj.network1).indexes;
            point2_indexes = obj.network_atlas.nets(obj.network2).indexes;

            edges = [];
            for point1_index = 1:numel(point1_indexes)
                point1 = point1_indexes(point1_index);
                for point2_index = 1:numel(point2_indexes)
                    point2 = point2_indexes(point2_index);
                    if point1 < point2
                        network_point1 = point2;
                        network_point2 = point1;
                    else
                        network_point1 = point1;
                        network_point2 = point2;
                    end
                    
                    [coefficient, ~, function_connectivity_vector, ~] = obj.getCoefficients(network_point1, network_point2);
                    function_connectivity_average = mean(function_connectivity_vector);
                
                    if ~isempty(coefficient)
                        edge = obj.assignColorToEdge(ROI_position, network_point1, network_point2, plot_axis, coefficient, function_connectivity_average);
                        % colorbar(plot_axis, 'off');
                        % hold(plot_axis, 'on');
                        edge.Annotation.LegendInformation.IconDisplayStyle = "off";
                        edges = [edges, edge];
                    end
                end
            end
        end

        function edge = assignColorToEdge(obj, ROI_position, network_point1, network_point2, plot_axis, coefficient, function_connectivity_average, varargin)
            if ~isempty(coefficient)
                if ~isempty(varargin)
                    color_value = obj.mapColorsToLimits(coefficient, function_connectivity_average, varargin{1}, varargin{2});
                else
                    color_value = obj.mapColorsToLimits(coefficient, function_connectivity_average);
                end
                color_value = [reshape(color_value, [1, 3]), 0.5];
                edge = plot3(plot_axis, [ROI_position(network_point1, 1), ROI_position(network_point2, 1)],...
                    [ROI_position(network_point1, 2), ROI_position(network_point2, 2)],...
                    [ROI_position(network_point1, 3), ROI_position(network_point2, 3)],...
                    "Color", color_value, "LineWidth", 5);
                % Matlab says you can save a structure to the "UserData" field of a line. You cannot. so, we do something dumb
                edge_data = {};
                edge_data{1} = {"coefficient", "function_connectivity_average"};
                edge_data{2} = {coefficient, function_connectivity_average};
                set(edge, "UserData", edge_data)
            end
        end

        function drawCortex(obj, anatomy, plot_axis, view_position, left_color, right_color)
            import nla.gfx.ViewPos

            % Set some defaults up
            plot_axis.Color = 'w';
            if ~exist("left_color", "var")
                left_color = repmat(0.5, [size(anatomy.hemi_l.nodes, 1), 3]);
            end
            if ~exist("right_color", "var")
                right_color = repmat(0.5, [size(anatomy.hemi_r.nodes, 1), 3]);
            end

            % Re-position hemisphere meshes to transverse/axial orientation
            [left_mesh, right_mesh] = nla.gfx.anatToMesh(anatomy, obj.mesh_type, view_position);

            % Set lighting and view positioning
            if view_position == ViewPos.LAT || view_position == ViewPos.MED
                view(plot_axis, [-90, 0]);
                % local light is akin to a lightbulb at that location in space
                % infinite light has light that originates at that point and only goes in one direction
                light(plot_axis, "Position", [-100, 200, 0], "Style", "local");
                light(plot_axis, "Position", [-50, -500, 100], "Style", "infinite");
                light(plot_axis, "Position", [-50, 0, 0], "Style", "infinite");
            else
                view(plot_axis, [0, 0]);
                switch view_position                      
                    case ViewPos.DORSAL
                        view(plot_axis, [0, 90]);
                        light(plot_axis, "Position", [100, 300, 100], "Style", "infinite");
                    case ViewPos.LEFT
                        view(plot_axis, [-90, 0]);
                        light(plot_axis, "Position", [-100, 0, 0], "Style", "infinite");
                    case ViewPos.RIGHT
                        view(plot_axis, [90, 0]);
                        light(plot_axis, "Position", [100, 0, 0], "Style", "infinite");
                    case ViewPos.FRONT
                        view(plot_axis, [180, 0]);
                        light(plot_axis, "Position", [100, 300, 100], "Style", "infinite");
                    case ViewPos.BACK
                        light(plot_axis, "Position", [0, -200, 0], "Style", "infinite");
                end
                
                light(plot_axis, "Position", [-500, -20, 0], "Style", "local");
                light(plot_axis, "Position", [500, -20, 0], "Style", "local");
                light(plot_axis, "Position", [0, -200, 50], "Style", "local");
            end
            left_hemisphere = obj.drawCortexHemisphere(plot_axis, anatomy.hemi_l, left_mesh, left_color);
            right_hemisphere = obj.drawCortexHemisphere(plot_axis, anatomy.hemi_r, right_mesh, right_color);

            hold(plot_axis, "on");
            axis(plot_axis, "image");
            axis(plot_axis, "off");
        end

        function hemisphere = drawCortexHemisphere(obj, plot_axis, hemisphere_anatomy, mesh, color)
            hemisphere = patch(plot_axis, "Faces", hemisphere_anatomy.elements(:, 1:3), "Vertices", mesh,...
                "EdgeColor", "none", "FaceColor", "interp", "FaceVertexCData", color,...
                "FaceLightin", "gouraud", "FaceAlpha", obj.mesh_alpha, "AmbientStrength", 0.25,...
                "DiffuseStrength", 0.75, "SpecularStrength", 0.1);
            hemisphere.Annotation.LegendInformation.IconDisplayStyle = "off";
        end

        function edges = singlePlot(obj, plot_axis, view_position, color_mode, color_matrix, upper_limit, lower_limit)

            if exist("upper_limit", "var")
                obj.upper_limit = upper_limit;
            end
            if exist("lower_limit", "var")
                obj.lower_limit = lower_limit;
            end

            connectivity_map = ~isnan(obj.ROI_values);

            edges = [];
            if color_mode == nla.gfx.BrainColorMode.NONE
                [ROI_final_positions, ~] = obj.getROIPositions(view_position, color_mode, color_matrix);
                obj.drawCortex(obj.network_atlas.anat, plot_axis, view_position);
                edges = [edges, obj.drawEdges(ROI_final_positions, plot_axis)];
            else
                obj.mesh_alpha = 1;
                [ROI_final_positions, ROI_colors] = obj.getROIPositions(view_position, nla.gfx.BrainColorMode.COLOR_ROIS);
                if ~isequal(color_mode, nla.gfx.BrainColorMode.NONE) && obj.surface_parcels && ~islogical(obj.network_atlas.parcels) && isequal(size(obj.network_atlas.parcels.ctx_l,1), size(obj.network_atlas.anat.hemi_l.nodes, 1)) && isequal(size(obj.network_atlas.parcels.ctx_r, 1), size(obj.network_atlas.anat.hemi_r.nodes, 1))
                    ROI_color_map = [0.5 0.5 0.5; ROI_colors];
                    obj.drawCortex(obj.network_atlas.anat, plot_axis, view_position, ROI_color_map(obj.network_atlas.parcels.ctx_l + 1, :), ROI_color_map(obj.network_atlas.parcels.ctx_r + 1, :));
                else
                drawCortex(ax, net_atlas.anat, ctx, obj.mesh_alpha, view_pos);
                    if color_mode ~= BrainColorMode.NONE
                        for i = 1:net_atlas.numROIs()
                            % render a sphere at each ROI location
                            nla.gfx.drawSphere(ax, ROI_final_positions(i, :), ROI_colors(i, :), obj.ROI_radius);
                        end
                    end
                end
            end
           
            if (~isfield(obj.edge_test_options, "show_ROI_centroids")) || (isfield(obj.edge_test_options, "show_ROI_centroids") && isequal(obj.edge_test_options.show_ROI_centroids, true))
                obj.drawROISpheres(ROI_final_positions, plot_axis, connectivity_map);
            end

            colorbar(plot_axis, "off");
            hold(plot_axis, "on");
        end

        function drawROISpheres(obj, ROI_position, plot_axis, connectivity_map)

            for network = [obj.network1, obj.network2]
                network_indexes = obj.network_atlas.nets(network).indexes;
                for index_iterator = 1:numel(network_indexes)
                    index = network_indexes(index_iterator);
                    
                    if connectivity_map(index)
                        nla.gfx.drawSphere(plot_axis, ROI_position(index, :), obj.network_atlas.nets(network).color, obj.ROI_radius);
                    end
                end
            end
        end

        function [ROI_final_positions, ROI_colors] = getROIPositions(obj, view_position, color_mode, color_matrix)
            import nla.gfx.BrainColorMode

            [left_mesh, right_mesh] = nla.gfx.anatToMesh(obj.network_atlas.anat, obj.mesh_type, view_position);
            ROI_positions = [obj.network_atlas.ROIs.pos]';

            [left_indexes, left_distances] = knnsearch(obj.network_atlas.anat.hemi_l.nodes, ROI_positions);
            [right_indexes, right_distances] = knnsearch(obj.network_atlas.anat.hemi_r.nodes, ROI_positions);

            for network = 1:obj.network_atlas.numNets()
                for network_indexes = 1:numel(obj.network_atlas.nets(network).indexes)
                    ROI_index = obj.network_atlas.nets(network).indexes(network_indexes);
                    offset = [NaN NaN NaN];
                    if left_distances(ROI_index) < right_distances(ROI_index)
                        offset = left_mesh(left_indexes(ROI_index), :) - obj.network_atlas.anat.hemi_l.nodes(left_indexes(ROI_index), :);
                    else
                        offset = right_mesh(right_indexes(ROI_index), :) - obj.network_atlas.anat.hemi_r.nodes(right_indexes(ROI_index), :);
                    end
                    ROI_final_positions(ROI_index, :) = ROI_positions(ROI_index, :) + offset;

                    switch color_mode
                        case BrainColorMode.DEFAULT_NETS
                            ROI_colors(ROI_index, :) = obj.network_atlas.nets(network).color;
                        case BrainColorMode.COLOR_NETS
                            ROI_colors(ROI_index, :) = color_matrix(network, :);
                        case BrainColorMode.COLOR_ROIS
                            ROI_colors(ROI_index, :) = color_matrix(ROI_index, :);
                        otherwise
                            ROI_colors = false;
                    end
                end
            end
        end

        function drawColorMap(obj, plot_axis)
            if obj.color_functional_connectivity
                colormap(plot_axis, obj.color_map);
                obj.color_bar = colorbar(plot_axis);
                obj.color_bar.Location = "southoutside";
                set(obj.color_bar, 'ButtonDownFcn', @obj.openModal);
            else
                colormap(plot_axis, obj.color_map);
                obj.color_bar = colorbar(plot_axis);
                obj.color_bar.Location = "southoutside";
                set(obj.color_bar, 'ButtonDownFcn', @obj.openModal);
                
                number_of_ticks = 10;
                ticks = 0:number_of_ticks;
                obj.color_bar.Ticks = double(ticks) ./ number_of_ticks;
                tick_labels = cell(number_of_ticks + 1, 1);
                for tick = ticks
                    tick_labels{tick + 1} = sprintf("%.2g", obj.lower_limit + (tick * ((double(obj.upper_limit - obj.lower_limit) / number_of_ticks))));
                end
                obj.color_bar.TickLabels = tick_labels;
                caxis(plot_axis, [0, 1]);
            end
        end

        function addTitle(obj)
            figure_title = sprintf("Brain Visualization: Average of edge-level correlations between nets in [%s - %s] Network Pair", obj.network_atlas.nets(obj.network1).name, obj.network_atlas.nets(obj.network2).name);
            if obj.is_noncorrelation_input
                figure_title = [figure_title sprintf("  (Edge-level P < %.2g)", obj.edge_test_options.prob_max)];
            end
            obj.plot_figure.Name = figure_title;
        end

        function openModal(obj, source, ~)
            d = figure("WindowStyle", "normal", "Units", "pixels", "Position", [obj.plot_figure.Position(1) + 10, obj.plot_figure.Position(2) + 10, obj.plot_figure.Position(3) / 2, obj.plot_figure.Position(4) / 2]);
            
            upper_limit_box_position = [120, 90, 100, 30];
            upper_limit_box = uicontrol("Style", "edit", "Units", "pixels", "String", obj.upper_limit, "Position", upper_limit_box_position);
            uicontrol("Style", "text", "Units", "pixels", "String", "Upper Limit", "Position", [upper_limit_box_position(1) - 90, upper_limit_box_position(2) - 2, 80, upper_limit_box_position(4) - 5]);
            lower_limit_box_position = [120, 50, 100, 30];
            lower_limit_box = uicontrol("Style", "edit", "Units", "pixels", "String", obj.lower_limit, "Position", lower_limit_box_position);
            uicontrol("Style", "text", "Units", "pixels", "String", "Lower Limit", "Position", [lower_limit_box_position(1) - 90, lower_limit_box_position(2) - 2, 80, lower_limit_box_position(4) - 5]);
            apply_button_position = [10, 10, 100, 30];
            uicontrol("String", "Apply", "Callback", {@obj.applyScale, upper_limit_box, lower_limit_box}, "Units", "pixels", "Position", apply_button_position); % Apply Button
            default_button_position = [apply_button_position(1) + apply_button_position(3) + 10, apply_button_position(2), apply_button_position(3), apply_button_position(4)];
            uicontrol("String", "Default", "Callback", {@obj.setDefaults, upper_limit_box, lower_limit_box}, "Units", "pixels", "Position", default_button_position);
            close_button_position = [default_button_position(1) + default_button_position(3) + 10, default_button_position(2), default_button_position(3), default_button_position(4)]; 
            uicontrol("String", "Close", "Callback", @(~, ~)close(d), "Units", "pixels", "Position", close_button_position);
        end

        function applyScale(obj, ~, ~, upper_value, lower_value)
            colorbar(obj.color_bar, "off");
            obj.upper_limit = str2double(upper_value.String);
            obj.lower_limit = str2double(lower_value.String);
            for edge = obj.all_edges
                edge_data = edge.UserData;
                edge_data_struct = struct();
                edge_data_names = edge_data{1};
                edge_data_values = edge_data{2};
                for idx = 1:numel(edge_data_names)
                    edge_data_struct.(edge_data_names{idx}) = edge_data_values{idx};
                end
                color_value = obj.mapColorsToLimits(edge_data_struct.coefficient, edge_data_struct.function_connectivity_average, obj.lower_limit, obj.upper_limit);
                color_value = [reshape(color_value, [1, 3]), 0.5];
                set(edge, "Color", color_value);
            end
            obj.drawColorMap(obj.color_map_axis);
        end  

        function setDefaults(obj, ~, ~, upper_limit_box, lower_limit_box)
            set(upper_limit_box, "String", obj.default_settings.upper_limit);
            set(lower_limit_box, "String", obj.default_settings.lower_limit);
        end

        %% 
        % GETTERS for dependent properties
        function value = get.is_noncorrelation_input(obj)
            % Convenience method to determine if inputs were correlation coefficients, or "significance" values
            value = any(strcmp(obj.noncorrelation_input_tests, obj.test_name));
        end

        function value = get.functional_connectivity_exists(obj)
            value = isfield(obj.edge_test_options, "func_conn");
        end

        function value = get.color_functional_connectivity(obj)
            value = false;
        end
        %%
    end
end