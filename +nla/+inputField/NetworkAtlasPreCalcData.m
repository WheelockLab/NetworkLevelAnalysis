classdef NetworkAtlasPreCalcData < nla.inputField.InputField
    %NETWORKATLAS Network atlas, contains network + ROI details
    properties (Constant)
        name = 'net_atlas'
        disp_name = 'Network atlas/Precalculated data';
    end
    
    properties
        net_atlas = false
        sim_obs = false
        sim_obs_unordered = false
        sim_perm = false
        sim_perm_unordered = false
    end
    
    properties (Access = protected)
        button = false
        button_view_net_atlas = false
        checkbox_surface_parcels = false
        button2 = false
        button3 = false
        label = false
        label2 = false
        label3 = false
        inflation_label = false
        inflation_dropdown = false
    end
    
    methods
        function obj = NetworkAtlasPreCalcData()
            import nla.* % required due to matlab package system quirks
            obj.satisfied = false;
        end
        
        function [w, h] = draw(obj, x, y, parent, fig)
            import nla.* % required due to matlab package system quirks
            
            obj.fig = fig;
            
            label_gap = inputField.LABEL_GAP;
            h = (inputField.LABEL_H * 3) + (label_gap * 2);
            
            %% Create label
            if ~isgraphics(obj.label)
                obj.label = uilabel(parent);
            end
            obj.label.Text = 'Network atlas:';
            label_w = inputField.widthOfString(obj.label.Text, inputField.LABEL_H);
            obj.label.HorizontalAlignment = 'left';
            obj.label.Position = [x, y - inputField.LABEL_H, label_w + label_gap, inputField.LABEL_H];
            
            %% Create button
            if ~isgraphics(obj.button)
                obj.button = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.buttonClickedCallback());
            end
            button_w = 100;
            obj.button.Position = [x + label_w + label_gap, y - inputField.LABEL_H, button_w, inputField.LABEL_H];
            
            %% Mesh inflation selector
            if ~isgraphics(obj.inflation_label)
                obj.inflation_label = uilabel(parent);
                obj.inflation_label.HorizontalAlignment = 'right';
                obj.inflation_label.Text = 'Inflation: ';
            end
            inflation_label_w = inputField.widthOfString(obj.inflation_label.Text, inputField.LABEL_H);
            obj.inflation_label.Position = [0, y - inputField.LABEL_H, inflation_label_w, inputField.LABEL_H];

            inflation_dropdown_w = 55;
            if ~isgraphics(obj.inflation_dropdown)
                obj.inflation_dropdown = uidropdown(parent);
                obj.inflation_dropdown.Items = ["Std", "Inf", "VInf"];
                obj.inflation_dropdown.ItemsData = {gfx.MeshType.STD, gfx.MeshType.INF, gfx.MeshType.VINF};
            end
            obj.inflation_dropdown.Position = [0, y - inputField.LABEL_H, inflation_dropdown_w, inputField.LABEL_H];
            
            %% 'View as surface parcel' checkbox
            checkbox_surface_parcels_w = 108;
            if ~isgraphics(obj.checkbox_surface_parcels)
                obj.checkbox_surface_parcels = uicheckbox(parent);
                obj.checkbox_surface_parcels.Text = ' Surface parcels';
            end
            obj.checkbox_surface_parcels.Position = [0, y - inputField.LABEL_H, checkbox_surface_parcels_w, inputField.LABEL_H];
            
            %% Create view button
            if ~isgraphics(obj.button_view_net_atlas)
                obj.button_view_net_atlas = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.buttonViewNetAtlasClickedCallback());
            end
            button_view_net_atlas_w = 45;
            obj.button_view_net_atlas.Text = 'View';
            obj.button_view_net_atlas.Position = [0, y - inputField.LABEL_H, button_view_net_atlas_w, inputField.LABEL_H];
            
            w = label_w + label_gap + button_w + label_gap + checkbox_surface_parcels_w + label_gap + button_view_net_atlas_w;
            
            %% Create label2
            if ~isgraphics(obj.label2)
                obj.label2 = uilabel(parent);
            end
            obj.label2.Text = 'Simulated data (observed):';
            label2_w = inputField.widthOfString(obj.label2.Text, inputField.LABEL_H);
            obj.label2.HorizontalAlignment = 'left';
            obj.label2.Position = [x, y - (inputField.LABEL_H * 2) - label_gap, label2_w + label_gap, inputField.LABEL_H];
            
            %% Create button2
            if ~isgraphics(obj.button2)
                obj.button2 = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.button2ClickedCallback());
            end
            button2_w = 100;
            obj.button2.Position = [x + label2_w + label_gap, y - (inputField.LABEL_H * 2) - label_gap, button2_w, inputField.LABEL_H];
            w2 = label2_w + label_gap + button2_w;
            
            %% Create label3
            if ~isgraphics(obj.label3)
                obj.label3 = uilabel(parent);
            end
            obj.label3.Text = 'Simulated data (permuted):';
            label3_w = inputField.widthOfString(obj.label3.Text, inputField.LABEL_H);
            obj.label3.HorizontalAlignment = 'left';
            obj.label3.Position = [x, y - h, label3_w + label_gap, inputField.LABEL_H];
            
            %% Create button3
            if ~isgraphics(obj.button3)
                obj.button3 = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.button3ClickedCallback());
            end
            button3_w = 100;
            obj.button3.Position = [x + label3_w + label_gap, y - h, button3_w, inputField.LABEL_H];
            w3 = label3_w + label_gap + button3_w;
            
            w = max([w, w2, w3]);
        end
        
        function undraw(obj)
            import nla.* % required due to matlab package system quirks
            if isgraphics(obj.button)
                delete(obj.button)
            end
            if isgraphics(obj.checkbox_surface_parcels)
                delete(obj.checkbox_surface_parcels)
            end
            if isgraphics(obj.button_view_net_atlas)
                delete(obj.button_view_net_atlas)
            end
            if isgraphics(obj.button2)
                delete(obj.button2)
            end
            if isgraphics(obj.button3)
                delete(obj.button3)
            end
            if isgraphics(obj.label)
                delete(obj.label)
            end
            if isgraphics(obj.label2)
                delete(obj.label2)
            end
            if isgraphics(obj.label3)
                delete(obj.label3)
            end
            if isgraphics(obj.inflation_label)
                delete(obj.inflation_label)
            end
            if isgraphics(obj.inflation_dropdown)
                delete(obj.inflation_dropdown)
            end
        end
        
        function read(obj, input_struct)
            import nla.* % required due to matlab package system quirks
            obj.loadField(input_struct, 'net_atlas');
            obj.loadField(input_struct, 'sim_obs');
            obj.loadField(input_struct, 'sim_obs_unordered');
            obj.loadField(input_struct, 'sim_perm');
            obj.loadField(input_struct, 'sim_perm_unordered');
            
            if isfield(input_struct, 'surface_parcels')
                obj.checkbox_surface_parcels.Value = input_struct.surface_parcels;
            else
                obj.checkbox_surface_parcels.Value = false;
            end
            
            obj.update();
        end
        
        function input_struct = store(obj, input_struct)
            import nla.* % required due to matlab package system quirks
            input_struct.net_atlas = obj.net_atlas;
            input_struct.sim_obs_unordered = obj.sim_obs_unordered;
            input_struct.sim_obs = obj.sim_obs;
            input_struct.sim_perm_unordered = obj.sim_perm_unordered;
            input_struct.sim_perm = obj.sim_perm;
            input_struct.surface_parcels = obj.checkbox_surface_parcels.Value;
        end
    end
    
    methods (Access = protected)
        function buttonClickedCallback(obj, ~)
            import nla.* % required due to matlab package system quirks
            [file, path, idx] = uigetfile({'*.mat', 'Network Atlas (*.mat)'}, 'Select Network Atlas');
            if idx ~= 0
                % Load file to net_atlas, depending on the filetype. Right now
                % it only supports .mat network atlases but if another file
                % type were added, it would be handled under idx == 2 and so on
                if idx == 1
                    prog = uiprogressdlg(obj.fig, 'Title', 'Loading network atlas', 'Message', sprintf('Loading %s', file), 'Indeterminate', true);
                    drawnow;
                    
                    try
                        obj.net_atlas = NetworkAtlas([path file]);
                        if ~islogical(obj.net_atlas.parcels)
                            obj.checkbox_surface_parcels.Value = true;
                        end
                        
                        obj.update();
                        close(prog);
                    catch ex
                        close(prog);
                        uialert(obj.fig, ex.message, 'Error while loading network atlas');
                    end
                end
            end
        end
        
        function button2ClickedCallback(obj, ~)
            import nla.* % required due to matlab package system quirks
            [file, path, idx] = uigetfile({'*.mat', 'Simulated observed coeffs (*.mat)'}, 'Select Simulated Observed Coeffs Matrix');
            if idx == 1
                prog = uiprogressdlg(obj.fig, 'Title', 'Loading simulated observed coeffs', 'Message', sprintf('Loading %s', file), 'Indeterminate', true);
                drawnow;
                    
                sim_obs = load([path file]);
                sim_obs_unordered = false;
                if isnumeric(sim_obs)
                    sim_obs_unordered = fc_data;
                elseif isstruct(sim_obs)
                    fn = fieldnames(sim_obs);
                    if numel(fn) == 1
                        fname = fn{1};
                        if isnumeric(sim_obs.(fname))
                            sim_obs_unordered = sim_obs.(fname);
                        end
                    end
                end

                % functional connectivity matrix (not ordered/trimmed according to network atlas yet)
                if ~islogical(sim_obs_unordered)
                    obj.sim_obs_unordered = double(sim_obs_unordered);
                    
                    obj.update();
                    close(prog);
                else
                    close(prog);
                    uialert(obj.fig, sprintf('Could not load simulated observed coeff matrix from %s', file), 'Invalid simulated data file');
                end
            end
        end

         function button3ClickedCallback(obj, ~)
            import nla.* % required due to matlab package system quirks
            [file, path, idx] = uigetfile({'*.mat', 'Simulated permuted coeffs (*.mat)'}, 'Select Simulated Permuted Coeffs Matrix');
            if idx == 1
                prog = uiprogressdlg(obj.fig, 'Title', 'Loading simulated permuted coeffs', 'Message', sprintf('Loading %s', file), 'Indeterminate', true);
                drawnow;
                    
                sim_perm = load([path file]);
                sim_perm_unordered = false;
                if isnumeric(sim_perm)
                    sim_perm_unordered = fc_data;
                elseif isstruct(sim_perm)
                    fn = fieldnames(sim_perm);
                    if numel(fn) == 1
                        fname = fn{1};
                        if isnumeric(sim_perm.(fname))
                            sim_perm_unordered = sim_perm.(fname);
                        end
                    end
                end

                % functional connectivity matrix (not ordered/trimmed according to network atlas yet)
                if ~islogical(sim_perm_unordered)
                    obj.sim_perm_unordered = double(sim_perm_unordered);
                    
                    obj.update();
                    close(prog);
                else
                    close(prog);
                    uialert(obj.fig, sprintf('Could not load simulated permuted coeff matrix from %s', file), 'Invalid simulated data file');
                end
            end
        end
        
        function buttonViewNetAtlasClickedCallback(obj)
            import nla.* % required due to matlab package system quirks
            
            prog = uiprogressdlg(obj.fig, 'Title', 'Generating visualization', 'Message', 'Generating net atlas visualization', 'Indeterminate', true);
            drawnow;
            
            mesh_inf = obj.inflation_dropdown.Value;
            
            if obj.checkbox_surface_parcels.Value && ~islogical(obj.net_atlas.parcels) && size(obj.net_atlas.parcels.ctx_l, 1) == size(obj.net_atlas.anat.hemi_l.nodes, 1) && size(obj.net_atlas.parcels.ctx_r, 1) == size(obj.net_atlas.anat.hemi_r.nodes, 1)
                gfx.drawNetworkROIs(obj.net_atlas, mesh_inf, 1, 4, true);
            else
                gfx.drawNetworkROIs(obj.net_atlas, mesh_inf, 0.8, 4, false);
            end
            
            close(prog);
            drawnow();
        end
        
        function updateSimData(obj)
            import nla.* % required due to matlab package system quirks
            
            obj.sim_obs = false;
            obj.sim_perm = false;
            obj.satisfied = false;
            if ~islogical(obj.net_atlas) && ~islogical(obj.sim_obs_unordered) && ~islogical(obj.sim_perm_unordered)
                dims = size(obj.sim_obs_unordered);
                dims_perm = size(obj.sim_perm_unordered);
                if numel(dims) == 2 && dims(1) == nla.helpers.triNum(obj.net_atlas.numROIs - 1)
                    obj.sim_obs = TriMatrix(obj.net_atlas.numROIs);
                    obj.sim_obs.v = mean(zscore(obj.sim_obs_unordered), 2);
                    
                    if numel(dims_perm) == 2 && dims(1) == nla.helpers.triNum(obj.net_atlas.numROIs - 1)
                        obj.sim_perm = TriMatrix(obj.net_atlas.numROIs);
                        obj.sim_perm.v = zscore(obj.sim_perm_unordered);
                        obj.satisfied = true;
                    else
                        uialert(obj.fig, 'Network atlas and simulated permuted matrix do not match!', 'Mismatched input files', 'Icon', 'warning');
                    end
                else
                    uialert(obj.fig, 'Network atlas and simulated observed matrix do not match!', 'Mismatched input files', 'Icon', 'warning');
                end
            end
        end
        
        function update(obj)
            import nla.* % required due to matlab package system quirks
            
            obj.updateSimData();
            
            if islogical(obj.net_atlas)
                obj.button.Text = 'Select';
                obj.button_view_net_atlas.Enable = false;
                obj.checkbox_surface_parcels.Enable = false;
                obj.checkbox_surface_parcels.Value = false;
            else
                obj.button.Text = obj.net_atlas.name;
                obj.button_view_net_atlas.Enable = true;
                if ~islogical(obj.net_atlas.parcels)
                    obj.checkbox_surface_parcels.Enable = true;
                else
                    obj.checkbox_surface_parcels.Enable = false;
                    obj.checkbox_surface_parcels.Value = false;
                end
            end
            obj.button.Position(3) = inputField.widthOfString(obj.button.Text, inputField.LABEL_H) + inputField.widthOfString('  ', inputField.LABEL_H + inputField.LABEL_GAP);
            

            obj.inflation_label.Position(1) = obj.button.Position(1) + obj.button.Position(3) + inputField.LABEL_GAP;
            obj.inflation_dropdown.Position(1) = obj.button.Position(1) + obj.button.Position(3) + inputField.LABEL_GAP + obj.inflation_label.Position(3);
            
            obj.checkbox_surface_parcels.Position(1) = obj.button.Position(1) + obj.button.Position(3) + inputField.LABEL_GAP + obj.inflation_label.Position(3) + obj.inflation_dropdown.Position(3) + inputField.LABEL_GAP;
            obj.button_view_net_atlas.Position(1) = obj.button.Position(1) + obj.button.Position(3) + inputField.LABEL_GAP + obj.inflation_label.Position(3) + obj.inflation_dropdown.Position(3) + inputField.LABEL_GAP + obj.checkbox_surface_parcels.Position(3) + inputField.LABEL_GAP;
            
            if islogical(obj.sim_obs_unordered)
                obj.button2.Text = 'Select';
            else
                nstr = join(string(size(obj.sim_obs_unordered)), 'x');
                obj.button2.Text = [sprintf('Matrix (%s)', nstr)];
            end
            obj.button2.Position(3) = inputField.widthOfString(obj.button2.Text, inputField.LABEL_H) + inputField.widthOfString('  ', inputField.LABEL_H + inputField.LABEL_GAP);
            
            if islogical(obj.sim_perm_unordered)
                obj.button3.Text = 'Select';
            else
                nstr = join(string(size(obj.sim_perm_unordered)), 'x');
                obj.button3.Text = [sprintf('Matrix (%s)', nstr)];
            end
            obj.button3.Position(3) = inputField.widthOfString(obj.button3.Text, inputField.LABEL_H) + inputField.widthOfString('  ', inputField.LABEL_H + inputField.LABEL_GAP);
        end
    end
end

