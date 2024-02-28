classdef ChordPlot < handle
%CHORDPLOT - Class to construct and display chord plots for network and edge tests
%
%   obj = ChordPlot(network_atlas, axes, axis_width, plot_matrix, varargin)
%   network_atlas - network atlas object used
%   axes - the axis that the chord will be plotted in/on
%   axis_width - the height and width of the plot. It will always be a square, just one number needed
%   plot_matrix - the data to be shown
%   
%   named arguments:
%   direction - value of nla.gfx.SigType: INCREASING (default), DECREASING, ABS_INCREASING
%   color_map - a valid colormap. Can be either builtin or created/edited.
%   chord_type - value of nla.PlotType: CHORD (default), CHORD_EDGE
%   upper_limit - value that upper limits are clipped (default: 1)
%   lower_limit - value that lower limits are clipped (default: 0)
%   random_z_order - are the chords randomized (true) or sorted (false) (default: false)
%
    properties
        axes
        network_atlas
        axis_width
        plot_matrix
        direction
        chord_type
        upper_limit
        lower_limit
        random_z_order
        color_map
        network_start_radian_array = []
    end

    properties (Dependent)
        circle_radius
        text_radius
        space_between_networks_and_labels
        space_between_networks_radians
        inner_circle_radius
        chord_radius
        network_size_radians
        network_pair_size_radians
        number_of_networks
        ROI_size_radians
        cumulative_network_size
        network_size_radians_array
        number_of_ROIs
    end

    properties (Constant)
        text_width = 50
        circle_thickness = 3
        space_between_networks = 5
    end

    methods
        function obj = ChordPlot(network_atlas, axes, axis_width, plot_matrix, varargin)
            % Constructor with argument parsing
            % network_atlas, axes, axis_width, plot_matrix required in that order
            % named arguments go after in form of (..., "<argument_name>", <value>, ...);
            chord_input_parser = inputParser;
            addRequired(chord_input_parser, 'network_atlas');
            addRequired(chord_input_parser, 'axes');
            addRequired(chord_input_parser, 'axis_width');
            addRequired(chord_input_parser, 'plot_matrix');
            
            validColorMap = @(x) size(x, 2) == 3;
            addParameter(chord_input_parser, 'direction', nla.gfx.SigType.INCREASING, @isenum);
            addParameter(chord_input_parser, 'color_map', turbo(256), validColorMap);
            addParameter(chord_input_parser, 'chord_type', nla.PlotType.CHORD, @isenum);
            addParameter(chord_input_parser, 'upper_limit', 1, @isnumeric);
            addParameter(chord_input_parser, 'lower_limit', 0, @isnumeric);
            addParameter(chord_input_parser, 'random_z_order', false, @islogical);

            parse(chord_input_parser, network_atlas, axes, axis_width, plot_matrix, varargin{:});
            properties = {'network_atlas', 'axes', 'axis_width', 'plot_matrix', 'direction', 'chord_type', 'upper_limit',...
                'lower_limit', 'random_z_order', 'color_map'};

            for property = properties
                obj.(property{1}) = chord_input_parser.Results.(property{1});
            end
        end

        function drawChords(obj)
            %DRAWCHORD - method to display chord plot
            obj.createAxis();

            obj.createNetworkCircle();

            obj.connectNetworks();
        end

        %% Getters for Dependent Properties
        function value = get.circle_radius(obj)
            value = (obj.axis_width - (2 * obj.text_width)) / 2;
        end

        function value = get.text_radius(obj)
            value = obj.circle_radius + (obj.text_width / 4);
        end

        function value = get.space_between_networks_and_labels(obj)
            value = 6;
            if obj.chord_type == nla.PlotType.CHORD
                value = 3;
            end
        end

        function value = get.space_between_networks_radians(obj)
            value = atan(obj.space_between_networks / obj.circle_radius);
        end

        function value = get.inner_circle_radius(obj)
            value = obj.circle_radius - obj.circle_thickness;
        end

        function value = get.chord_radius(obj)
            value = obj.inner_circle_radius - obj.space_between_networks_and_labels;
        end

        function value = get.network_size_radians(obj)
            value = 2 * pi / obj.network_atlas.numNets();
        end

        function value = get.network_pair_size_radians(obj)
            value = (obj.network_size_radians - obj.space_between_networks_radians) / (obj.network_atlas.numNets() + 1);
        end

        function value = get.number_of_networks(obj)
            value = obj.network_atlas.numNets();
        end

        function value = get.ROI_size_radians(obj)
            ROI_size_radians = 2 * pi / obj.number_of_ROIs;
            value = ((2 * pi) - (obj.space_between_networks_radians * obj.number_of_networks)) ./ obj.number_of_ROIs;
        end

        function value = get.number_of_ROIs(obj)
            value = obj.network_atlas.numROIs();
        end

        function value = get.network_size_radians_array(obj)
            network_size = [];
            for network = 1:obj.number_of_networks
                network_size(network) = obj.network_atlas.nets(network).numROIs();
            end
            value = network_size .* obj.ROI_size_radians + obj.space_between_networks_radians;
        end

        function value = get.cumulative_network_size(obj)
            value = cumsum(obj.network_size_radians_array);
        end
        %%
    end

    methods (Access = protected)
        function createAxis(obj)
            %CREATEAXIS - method that creates axis to square size of axis_width x axis_width
            axis(obj.axes, [-obj.axis_width / 2, obj.axis_width / 2, -obj.axis_width / 2, obj.axis_width / 2]);
            set(obj.axes, 'xtick', [], 'ytick', []);
            hold(obj.axes, 'on');
        end

        function circle = circleRadians(obj, radius, angle, origin)
            % Circle function
            circle = [radius * cos(angle) + origin(1); radius * sin(angle) + origin(2)]';
        end

        function arc_points = generateArcSegmentWithCatch(obj, radius, angles, origin, arc_start, arc_end, points)
            % Wrapper for generateArcSegment. Catches arcs with almost no angle or tiny radii

            % ignore really tiny arcs
            if radius < 1e-10
                arc_points = origin;
            % Almost straight line/slope of 0
            elseif abs(angles(1) - angles(2)) < 1e-10
                arc_points = [arc_start; arc_end];
            else
                arc_points = obj.generateArcSegment(radius, angles, origin, points);
            end
        end

        function arc_points = generateArcSegment(obj, radius, angles, origin, points)
            % generateArcSegment - creates arcs that make up sections of the network circle or the chords themselves

            if nargin <= 4
                points = 50;
            end
            % First two conditions account for looping around
            if angles(1) > angles(2) && angles(1) - pi > angles(2)
                arc = linspace(angles(1), (2 * pi) + angles(2), points);
                arc = obj.correctLoopedArc(arc);
            elseif angles(2) > angles(1) && angles(2) - pi > angles(1)
                arc = linspace(angles(2), (2 * pi) + angles(1), points);
                arc = obj.correctLoopedArc(arc);
            else
                arc = linspace(angles(1), angles(2), points);
            end
            arc_points = obj.circleRadians(radius, arc, origin);
        end

        function arc = correctLoopedArc(obj, arc)
            % Method used in conjunction with generateArcSegment to remove values over 2pi
            looped_around_indexes = arc > (2 * pi);
            arc(looped_around_indexes) = arc(looped_around_indexes) - (2 * pi);
        end

        function createNetworkCircle(obj)
            % CREATENETWORKCIRCLE - creates the network circle that the chords will be drawn inside
            import nla.TriMatrix nla.TriMatrixDiag
            
            for network = 1:obj.number_of_networks
                if obj.chord_type == nla.PlotType.CHORD
                    network_start_radian = (network - 1) * obj.network_size_radians + (obj.space_between_networks_radians / 2);
                    network_end_radian = (network * obj.network_size_radians) - (obj.space_between_networks_radians / 2);
                else
                    network_outer_end_radians = obj.cumulative_network_size(network);
                    network_start_radian = network_outer_end_radians - obj.network_size_radians_array(network) +...
                        (obj.space_between_networks_radians / 2);
                    obj.network_start_radian_array(network) = network_start_radian;
                    network_end_radian = network_outer_end_radians - (obj.space_between_networks_radians / 2);
                end
                network_center_radian = (network_end_radian + network_start_radian) / 2;
                % create outer and inner arcs
                network_outer_arc = obj.generateArcSegment(obj.circle_radius, [network_start_radian, network_end_radian], [0, 0]);
                network_inner_arc = obj.generateArcSegment(obj.inner_circle_radius, [network_start_radian, network_end_radian], [0, 0]);
                % create polygon using the two arcs
                polygon_points = [network_outer_arc; flip(network_inner_arc, 1)]; % flip inner around so that ends match up
                polygon = polyshape(polygon_points(:, 1), polygon_points(:, 2));

                network_color = obj.network_atlas.nets(network).color;
                circle_plot = plot(obj.axes, polygon, "FaceColor", network_color, "EdgeColor", network_color, 'FaceAlpha', 1, 'EdgeAlpha', 1);
                % If the network is white, outline it in black so that we can see it
                if network_color == [1 1 1]
                    circle_plot.EdgeColor = [0 0 0];
                end

                % This arc is only three points, and we grab the middle one to center the name
                text_position = obj.generateArcSegment(obj.text_radius, [network_start_radian, network_end_radian], [0, 0], 3);
                text_position = text_position(2, :);
                text_angle = network_center_radian + (pi / 2); % Want the name perpendicular to the arc
                display_name = obj.network_atlas.nets(network).name;

                obj.rotateNetworkNames(display_name, text_angle, text_position, network);
            end

            % This is just a catch in case one of the connections goes a little over. This is a white circle around the interior of the
            % network circle
            viscircles(obj.axes, [0, 0], obj.inner_circle_radius - (obj.space_between_networks_and_labels / 2), 'Color', 'w',...
                'LineWidth', obj.space_between_networks_and_labels - 1);
        end

        function rotateNetworkNames(obj, display_name, text_angle, text_position, network)
            % Rotates the network names to match the angle of the network circle and keep them right side up
            %   display_name - the display name for the network, usually some 3-4 letter abbreviation
            %   text_angle - the angle the name should be displayed
            %   text_position - where the name is displayed. A list or array of points
            if obj.chord_type == nla.PlotType.CHORD_EDGE && (obj.network_size_radians_array(network) < 0.25) &&...
                (strlength(display_name) > 5)
                
                if strlength(display_name) > 8
                    display_name = sprintf("%.7s...", display_name);
                end
                text_angle = text_angle - (pi / 2);
                if (text_angle > pi / 2) && (text_angle < 1.5 * pi)
                    text_angle = text_angle - pi;
                    text(text_position(1), text_position(2), display_name, 'HorizontalAlignment', 'right', 'Rotation',...
                        rad2deg(text_angle));
                else
                    text(text_position(1), text_position(2), display_name, 'HorizontalAlignment', 'left', 'Rotation',...
                        rad2deg(text_angle));
                end
            else
                if text_position(2) > 0
                    text_angle = text_angle - pi;
                end 
                text(text_position(1), text_position(2), display_name, 'HorizontalAlignment', 'center',...
                    'Rotation', rad2deg(text_angle));
            end
        end

        function connectNetworks(obj)
            % This is an enormous method. There's a lot of setup at the beginning. Then, we move into creating the actual
            % chords. I've tried to break it up in many functions and keep things organized.
            import nla.gfx.SigType nla.TriMatrix nla.TriMatrixDiag

            % Sort the chords
            if obj.random_z_order
                plot_network_indexes = randperm(numel(obj.plot_matrix.v));
            elseif obj.direction == SigType.INCREASING
                [~, plot_network_indexes] = sort(obj.plot_matrix.v);
            elseif obj.direction == SigType.DECREASING
                [~, plot_network_indexes] = sort(obj.plot_matrix.v, 'descend');
            else
                [~, plot_network_indexes] = sort(abs(obj.plot_matrix.v));
            end

            % boolean array used to determine if networks connected
            networks_connected = false(obj.number_of_networks, obj.number_of_networks + 1);

            % These two arrays are the networks individucally numbered. Taking the same index of both
            % (in vector, network_array.v(idx)) gives the two networks we're testing
            network_array = TriMatrix(obj.number_of_networks, 'double', TriMatrixDiag.KEEP_DIAGONAL);
            network2_array = TriMatrix(obj.number_of_networks, 'double', TriMatrixDiag.KEEP_DIAGONAL);
            % These two arrays set up the placement in each network arc the chords will begin and end.
            % Again, taking the same index from both will give the start and end offsets within each arc
            network_indexes = TriMatrix(obj.number_of_networks, 'double', TriMatrixDiag.KEEP_DIAGONAL);
            network2_indexes = TriMatrix(obj.number_of_networks, 'double', TriMatrixDiag.KEEP_DIAGONAL);

            if obj.chord_type == nla.PlotType.CHORD_EDGE
                row_matrix = TriMatrix(repelem(1:obj.number_of_ROIs, obj.number_of_ROIs, 1)');
                column_matrix = TriMatrix(repelem(1:obj.number_of_ROIs, obj.number_of_ROIs, 1));
            end

            ROI_center_radians = [];
            ROI_centers = [];
            for network = 1:obj.number_of_networks
                if obj.chord_type == nla.PlotType.CHORD
                    % These fill in the four networks above.
                    for network2 = network:obj.number_of_networks
                        network_index = find(networks_connected(network, :) == 0, 1, 'last');
                        networks_connected(network, network_index) = true;

                        network2_index = find(networks_connected(network2, :) == 0, 1, 'last');
                        networks_connected(network2, network2_index) = true;

                        network_array.set(network2, network, network);
                        network2_array.set(network2, network, network2);
                        network_indexes.set(network2, network, network_index);
                        network2_indexes.set(network2, network, network2_index);
                    end
                else
                    for roi = 1:obj.network_atlas.nets(network).numROIs()
                        ROI_center_radian = obj.network_start_radian_array(network) + (((roi - 1) * obj.ROI_size_radians)) +...
                            (obj.ROI_size_radians / 2);
                        ROI_center = obj.generateArcSegment((obj.inner_circle_radius + obj.chord_radius) / 2,...
                            [ROI_center_radian, ROI_center_radian], [0, 0], 1);
                        ROI_center_radians(obj.network_atlas.nets(network).indexes(roi)) = ROI_center_radian;
                        ROI_centers(obj.network_atlas.nets(network).indexes(roi), :) = ROI_center;
                    end
                end
            end

            for index_iterator = 1:numel(obj.plot_matrix.v)
                index = plot_network_indexes(index_iterator);
                if ~isnan(obj.plot_matrix.v(index)) && (...
                    (obj.direction == SigType.INCREASING && obj.plot_matrix.v(index) > obj.lower_limit) ||...
                    (obj.direction == SigType.DECREASING && obj.plot_matrix.v(index) < obj.upper_limit) ||...
                    (obj.direction == SigType.ABS_INCREASING && abs(obj.plot_matrix.v(index)) > 0))
                    current_network = obj.plot_matrix.v(index);
                    network_color = nla.gfx.valToColor(current_network, obj.lower_limit, obj.upper_limit, obj.color_map);

                    network_alpha = 1;
                    if obj.random_z_order
                        network_alpha = 0.5;
                    end

                    if obj.chord_type == nla.PlotType.CHORD
                        network = network_array.v(index);
                        network2 = network2_array.v(index);
                        network_index = network_indexes.v(index);
                        network2_index = network2_indexes.v(index);

                        % Start of end of the networks, which will also be the place the chords start and end
                        % I know it looks weird having the chord1 and chord2 starts and ends mixed. But, there is an inner
                        % and outer circle we're looking for. So, the inner circle starts at network1 and ends at network2
                        % and the outer does the opposite. 
                        network_start_radian = (network - 1) * obj.network_size_radians +...
                            (obj.space_between_networks_radians / 2);
                        chord1_start_radian = network_start_radian + ((network_index - 1) * obj.network_pair_size_radians);
                        chord2_end_radian = chord1_start_radian + obj.network_pair_size_radians;
                        
                        network2_start_radian = (network2 - 1) * obj.network_size_radians +...
                            (obj.space_between_networks_radians / 2);
                        chord2_start_radian = network2_start_radian + ((network2_index - 1) * obj.network_pair_size_radians);
                        chord1_end_radian = chord2_start_radian + obj.network_pair_size_radians;
                        
                        [chord1_start_cartesian_x, chord1_start_cartesian_y] = pol2cart(chord1_start_radian, obj.chord_radius);
                        [chord1_end_cartesian_x, chord1_end_cartesian_y] = pol2cart(chord1_end_radian, obj.chord_radius);
                        [chord2_start_cartesian_x, chord2_start_cartesian_y] = pol2cart(chord2_start_radian, obj.chord_radius);
                        [chord2_end_cartesian_x, chord2_end_cartesian_y] = pol2cart(chord2_end_radian, obj.chord_radius);
                        chord1_start_cartesian = [chord1_start_cartesian_x, chord1_start_cartesian_y];
                        chord1_end_cartesian = [chord1_end_cartesian_x, chord1_end_cartesian_y];
                        chord2_start_cartesian = [chord2_start_cartesian_x, chord2_start_cartesian_y];
                        chord2_end_cartesian = [chord2_end_cartesian_x, chord2_end_cartesian_y];

                        [chord_inner_origin, chord_inner_radius, chord_inner_start_end_radian] = obj.findChordParameters(...
                            chord2_start_cartesian, chord2_end_cartesian...
                        );
                        [chord_outer_origin, chord_outer_radius, chord_outer_start_end_radian] = obj.findChordParameters(...
                            chord1_start_cartesian, chord1_end_cartesian...
                        );

                        inner = obj.generateArcSegmentWithCatch(chord_inner_radius, chord_inner_start_end_radian,...
                            chord_inner_origin, chord2_start_cartesian, chord2_end_cartesian, 50);
                        % We reverse the end and start because we want them to be a continuous shape, not two seperate shapes
                        % Without this, the arcs that are close to a straight line will be a straight line, and the other half of
                        % it will be an arc. Putting two chords (half the size) in place of one
                        outer = obj.generateArcSegmentWithCatch(chord_outer_radius, [chord_outer_start_end_radian(2),...
                            chord_outer_start_end_radian(1)], chord_outer_origin, chord1_end_cartesian,...
                            chord1_start_cartesian, 50);

                        mesh_vertices = [outer; flip(inner, 1)];
                        mesh = polyshape(mesh_vertices(:, 1), mesh_vertices(:, 2));

                        plot(obj.axes, mesh, 'FaceAlpha', network_alpha, 'FaceColor', network_color,...
                            'EdgeAlpha', network_alpha, 'EdgeColor', network_color);
                    else
                        column = column_matrix.v(index);
                        row = row_matrix.v(index);

                        column_center_radians = ROI_center_radians(column);
                        row_center_radians = ROI_center_radians(row);

                        column_arc = obj.generateArcSegment(obj.chord_radius + 1, [column_center_radians, column_center_radians],...
                            [0, 0], 1);
                        row_arc = obj.generateArcSegment(obj.chord_radius + 1, [row_center_radians, row_center_radians],...
                            [0, 0], 1);

                        [arc_origin, arc_radius, arc_start_end_radian] = obj.findChordParameters(row_arc, column_arc);
                        arc = obj.generateArcSegmentWithCatch(arc_radius, arc_start_end_radian, arc_origin, row_arc, column_arc, 50);
                        plot_color = [network_color(:); network_alpha];
                        plot(obj.axes, arc(:, 1), arc(:, 2), 'LineWidth', 2, 'Color', plot_color);
                    end
                end
            end

            if obj.chord_type == nla.PlotType.CHORD_EDGE
                % This is the inner circle of dots for the rois on the edge chord circle
                for roi = 1:obj.number_of_ROIs
                    plot(obj.axes, ROI_centers(roi, 1), ROI_centers(roi, 2), '.k', 'MarkerSize', 3);
                end
            end
        end

        function [x, y] = findOriginOfCircleFromTwoTangents(obj, point1, point2)
            % Finds the origin of a circle from two tangents. 
            %   point1 - cartesian coordinates of a point forming a line to the origin
            %   point2 - cartesian coordinates of a second point for a line to the origin
            %   [x, y] - cartesian coordinates of a circle tangential to both

            % Point1 and Point2 are cartesian coordinates both connected to [0, 0];
            % The slope of the tangent lines are then just y / x for both
            % The radius of the circle we're looking for is equidistant from both, 
            % and the connections are perpendicular (tangents are always
            % perpendicular to the radius). So their slopes are -x / y (perpendicular lines have
            % negative-reciprocal slopes)
            slope1 = point1(2) / point1(1);
            slope2 = point2(2) / point2(1);
            m1 = (-1 / slope1);
            m2 = (-1 / slope2);

            point1_center_y_intercept = point1(2) + (1 / slope1) * point1(1);

            % This is all basic geometry. y = mx + b. Since we're looking for the intersection
            % we can set both lines equal to each other. Two equations, two unknownss, solve for x.
            % Geometry 101 FTW!!!
            x = (point2(2) - point1(2) + m1 * point1(1) - m2 * point2(1)) / (m1 - m2);
            y = m1 * x + point1_center_y_intercept;
        end 

        function angle = findAngleBetweenOriginAndPoint(obj, point, origin)
            % Finds the angle between the origin of a circle and a point on the edge
            %   point - cartesian coordinates for point of interest
            %   origin - cartesian coordinates of the origin
            %   angle - the result angle in radians
            dx = point(1) - origin(1);
            dy = point(2) - origin(2);

            angle = abs(atan(dy / dx));

            % quadrant 2
            if dx < 0 && dy >= 0
                angle = pi - angle;
            % quadrant 3
            elseif dx < 0 && dy < 0
                angle = angle + pi;
            % quadrant 4
            elseif dx >= 0 && dy < 0
                angle = (2 * pi) - angle;
            end
        end

        function [chord_origin, radius, start_end_radians] = findChordParameters(obj, cartesian_start,...
            cartesian_end)
            % Finds the coordinates needed to draw the chords in the figure
            %   cartesian_start - the x-y pair of the starting point for the chord
            %   cartesian_end - the x-y pair of the ending point for the chord
            %   chord_origin - the x-y pair of the center of the circle the chord is from (the chords are
            %   arcs of that circle)
            %   radius - the radius of the chord circle
            %   start_end_radians - the starting and ending radians of the chord

            [origin_x, origin_y] = obj.findOriginOfCircleFromTwoTangents(cartesian_start, cartesian_end);
            radius = pdist([cartesian_start; origin_x, origin_y]);
            start_radian = obj.findAngleBetweenOriginAndPoint(cartesian_start, [origin_x, origin_y]);
            end_radian = obj.findAngleBetweenOriginAndPoint(cartesian_end, [origin_x, origin_y]);
            
            chord_origin = [origin_x, origin_y];
            start_end_radians = [start_radian, end_radian];
        end
    end
end