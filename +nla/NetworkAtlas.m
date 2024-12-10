classdef NetworkAtlas < nla.DeepCopyable
    % Network atlas (also known as infomap)
    % Defines ROI positions/information and networks
    %
    % :param name: The name of the atlas
    % :param net_names: N\ :sub:`nets`\ x 3 matrix. The names of the networks
    % :param ROI_key: N\ :sub:`ROIs`\ x 2 matrix. First column is ROI (Region Of Interest) indexes, second column is the network they belong to
    % :param ROI_order: N\ :sub:`ROIs`\ x 1 vector. Functional Connectivity data indexes corresponding to ROIs
    % :param ROI_pos: N\ :sub:`ROIs`\ x 3 matrix. Centroid positions for each ROI.
    % :param net_colors: N\ :sub:`nets`\ x 3 matrix. The color of each network when plotted.
    % :param parcels: Optional MATLAB struct field for surface parcellations. Contains two sub-fields ``ctx_l`` and ``ctx_r``. N\ :sub:`verts`\ x 1 vectors. Each element of a vector corresponds to a vertex within the spatial mesh and contains the index of the ROI for that vertex.
    % :param space: Optional The mesh that the atlas` ROI locations/parcels are in. Two options - ``TT`` or ``MNI``

    
    properties (SetAccess = private)
        nets % This is the net_names
        ROIs
        ROI_order
        name
        space
        anat = false;
        parcels = false;
    end
    
    methods
        function obj = NetworkAtlas(fname)
            %% IM structure
            if ischar(fname) || isstring(fname)
                net_struct = load(fname);
            else
                % loading directly from struct
                net_struct = fname;
            end
            
            net_names = net_struct.net_names;
            
            net_count = numel(net_names);
            ROI_count = size(net_struct.ROI_key, 1);
            
            net_colors = turbo(net_count);
            if isfield(net_struct, 'net_colors')
                net_colors = net_struct.net_colors;
            end
            
            ROI_positions = zeros(ROI_count, 3);
            if isfield(net_struct, 'ROI_pos')
                ROI_positions = net_struct.ROI_pos;
            end
            
            %% Solve improperly ordered ROI issues
            if ~issorted(net_struct.ROI_key(:, 2))
                [~, sort_idx] = sort(net_struct.ROI_key(:, 2));
                
                net_struct.ROI_key(:, 1) = [1:ROI_count];
                net_struct.ROI_key(:, 2) = net_struct.ROI_key(sort_idx, 2);
                net_struct.ROI_order = net_struct.ROI_order(sort_idx);
                ROI_positions = ROI_positions(sort_idx, :);
            end
            
            %% Network atlas name
            obj.name = net_struct.name;
            
            %% Space
            obj.space = net_struct.space;
            
            %% Regions of interest
            for i = 1:ROI_count
                obj.ROIs = [obj.ROIs; nla.ROI(ROI_positions(i, :)')];
            end

            %% ROI order(re-orders elements of func_conn)
            obj.ROI_order = uint32(net_struct.ROI_order);
            
            %% Networks
            obj.nets = nla.Network.empty();
            for i = 1:net_count
                obj.nets(i) = nla.Network(net_names{i}, net_colors(i,:), []);
            end
            % ensure column vector form
            obj.nets = obj.nets(:);
            
            for i = 1:ROI_count
                ROI_index = net_struct.ROI_key(i, 1);
                net_index = net_struct.ROI_key(i, 2);
                obj.nets(net_index).addROI(ROI_index);
            end
            
            %% Cortex anatomy
            try
                obj.anat = nla.CortexAnatomy(sprintf('%ssupport_files/meshes/%s.mat', nla.findRootPath(), obj.space));
            catch
                error("Could not load cortex anatomy - you may have forgotten to set the 'space' field in your Network Atlas")
            end
            
            %% Parcels (optional)
            if isfield(net_struct, 'parcels') && isfield(net_struct.parcels, 'ctx_l') && isfield(net_struct.parcels, 'ctx_r')
                % Invert ROI_order so we can index it with the parcel's ROI
                % indexes. Also add a 'zeroth' ROI for non-assigned
                % vertices
                ROI_inverse_order_map(obj.ROI_order) = [1:ROI_count];
                ROI_inverse_order_map_with_missing = [0; ROI_inverse_order_map'];
                
                obj.parcels = struct();
                % Index the inverted order with indices contained in parcel
                % The resulting parcels match the correct, ordered ROIs and
                % nothing more must be done to index them - except that
                % some parcels are assigned zero, which means no ROI
                % associated to said parcel.
                obj.parcels.ctx_l = ROI_inverse_order_map_with_missing(net_struct.parcels.ctx_l + 1);
                obj.parcels.ctx_r = ROI_inverse_order_map_with_missing(net_struct.parcels.ctx_r + 1);
            end
        end
        
        function val = numNets(obj)
            % :returns: The number of networks
            val = numel(obj.nets);
        end
        
        function val = numNetPairs(obj)
            % :returns: The number of network pairs
            val = nla.helpers.triNum(numel(obj.nets));
        end
        
        function val = numROIs(obj)
            % :returns: The number of Regions Of Interest (ROIT)
            val = numel(obj.ROIs);
        end
        
        function val = numROIPairs(obj)
            % :returns: The number of ROI pairs
            val = nla.helpers.triNum(numel(obj.ROIs) - 1);
        end
    end
end

