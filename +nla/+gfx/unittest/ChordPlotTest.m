classdef ChordPlotTest < matlab.unittest.TestCase
    properties
        network_atlas
        edge_test_options
        chord_plot
        plot_axes
        axis_width
        plot_matrix
        direction
        color_map
        chord_type
        upper_limit
        lower_limit
        z_order
    end

    methods (TestClassSetup)
        function loadTestData(testCase)
            import nla.TriMatrix
            import nla.gfx.chord.ChordPlot
            
            root_path = nla.findRootPath();

            % Load up a network atlas
            network_atlas_path = strcat(root_path, fullfile('support_files',...
                'Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat'));
            testCase.network_atlas = nla.NetworkAtlas(network_atlas_path);

            precalculated_path = strcat(root_path, fullfile('examples', 'precalculated/'));
            observed_p_file = load(strcat(precalculated_path, 'SIM_obs_p.mat'));
            testCase.edge_test_options.precalc_obs_p = TriMatrix(testCase.network_atlas.numROIs);
            testCase.edge_test_options.precalc_obs_p.v = observed_p_file.SIM_obs_p;

            testCase.plot_axes = axes();
            testCase.axis_width = 500;
            testCase.plot_matrix = testCase.edge_test_options.precalc_obs_p;
            testCase.direction = nla.gfx.SigType.INCREASING;
            testCase.color_map = parula(256);
            testCase.chord_type = nla.PlotType.CHORD_EDGE;
            testCase.upper_limit = 1;
            testCase.lower_limit = 0;
            testCase.z_order = true;

            testCase.chord_plot = ChordPlot(testCase.network_atlas, testCase.plot_axes, testCase.axis_width,...
                testCase.plot_matrix, 'direction', testCase.direction, 'color_map', testCase.color_map,...
                'chord_type', testCase.chord_type, 'upper_limit', testCase.upper_limit, 'lower_limit', testCase.lower_limit,...
                'random_z_order', testCase.z_order);
        end
    end

    methods (TestClassTeardown)
        function clearTestData(testCase)
            close all
            clear
        end
    end

    methods (Test)
        function initailizeChordPlotTest(testCase)
            
            testCase.verifyEqual(testCase.plot_axes, testCase.chord_plot.axes);
            testCase.verifyEqual(testCase.axis_width, testCase.chord_plot.axis_width);
            testCase.verifyEqual(testCase.plot_matrix, testCase.chord_plot.plot_matrix);
            testCase.verifyEqual(testCase.direction, testCase.chord_plot.direction);
            testCase.verifyEqual(testCase.color_map, testCase.chord_plot.color_map);
            testCase.verifyEqual(testCase.chord_type, testCase.chord_plot.chord_type);
            testCase.verifyEqual([testCase.upper_limit testCase.lower_limit],...
                [testCase.chord_plot.upper_limit testCase.chord_plot.lower_limit]);
            testCase.verifyEqual(testCase.z_order, testCase.chord_plot.random_z_order);
        end

        function getCircleRadiusTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.circle_radius, 200);
        end

        function getTextRadiusTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.text_radius, (...
                testCase.chord_plot.circle_radius + (testCase.chord_plot.text_width / 4)));
        end

        function getSpaceBetweenNetworksAndLabelsTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.space_between_networks_and_labels, 6);
            testCase.chord_plot.chord_type = nla.PlotType.CHORD;
            testCase.verifyEqual(testCase.chord_plot.space_between_networks_and_labels, 3);
        end

        function getSpaceBetweenNetworksAndLabelsRadiansTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.space_between_networks_radians,...
                atan(testCase.chord_plot.space_between_networks / testCase.chord_plot.circle_radius));
        end

        function getInnerCircleRadiusTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.inner_circle_radius,...
                testCase.chord_plot.circle_radius - testCase.chord_plot.circle_thickness);
        end

        function getChordRadiusTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.chord_radius,...
                testCase.chord_plot.inner_circle_radius - testCase.chord_plot.space_between_networks_and_labels);
        end

        function getNetworkSizeRadiansTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.network_size_radians, (2 * pi / testCase.network_atlas.numNets()));
        end

        function getNetworkPairSizeRadiansTest(testCase)
            expected_value = (testCase.chord_plot.network_size_radians - testCase.chord_plot.space_between_networks_radians) /...
                (testCase.network_atlas.numNets() + 1);
            testCase.verifyEqual(testCase.chord_plot.network_pair_size_radians, expected_value);
        end

        function getROISizeRadiansTest(testCase)
            expected_value = ((2 * pi) - (testCase.chord_plot.space_between_networks_radians * testCase.network_atlas.numNets())) ./...
                testCase.network_atlas.numROIs();
            testCase.verifyEqual(testCase.chord_plot.ROI_size_radians, expected_value);
        end

        function getNumberOfNetworksTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.number_of_networks, testCase.network_atlas.numNets());
        end

        function getNumberOfROIsTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.number_of_ROIs, testCase.network_atlas.numROIs());
        end

        function getNetworkSizeRadiansArrayTest(testCase)
            network_size = [];
            for network = 1:testCase.network_atlas.numNets()
                network_size(network) = testCase.network_atlas.nets(network).numROIs();
            end
            expected_value = network_size .* testCase.chord_plot.ROI_size_radians + testCase.chord_plot.space_between_networks_radians;
            testCase.verifyEqual(testCase.chord_plot.network_size_radians_array, expected_value);
        end

        function getCumulativeNetworkSizeTest(testCase)
            testCase.verifyEqual(testCase.chord_plot.cumulative_network_size, cumsum(testCase.chord_plot.network_size_radians_array));
        end
    end
end