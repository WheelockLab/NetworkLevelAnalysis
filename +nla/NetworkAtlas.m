classdef NetworkAtlas < nla.DeepCopyable
    %NETWORKATLAS Network atlas(also known as infomap)
    %   Defines ROI positions/information and networks
    
    properties (SetAccess = private)
        nets
        ROIs
        ROI_order
        name
        space
        anat = false;
        parcels = false;
    end
    
    methods
        function obj = NetworkAtlas(fname)
            import nla.* % required due to matlab package system quirks
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
                obj.ROIs = [obj.ROIs; ROI(ROI_positions(i, :)')];
            end

            %% ROI order(re-orders elements of func_conn)
            obj.ROI_order = uint32(net_struct.ROI_order);
            
            %% Networks
            obj.nets = Network.empty();
            for i = 1:net_count
                obj.nets(i) = Network(net_names{i}, net_colors(i,:), []);
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
                obj.anat = CortexAnatomy(sprintf('support_files/meshes/%s.mat', obj.space));
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
            import nla.* % required due to matlab package system quirks
            val = numel(obj.nets);
        end
        
        function val = numNetPairs(obj)
            import nla.* % required due to matlab package system quirks
            val = helpers.triNum(numel(obj.nets));
        end
        
        function val = numROIs(obj)
            import nla.* % required due to matlab package system quirks
            val = numel(obj.ROIs);
        end
        
        function val = numROIPairs(obj)
            import nla.* % required due to matlab package system quirks
            val = helpers.triNum(numel(obj.ROIs) - 1);
        end
    end
end

