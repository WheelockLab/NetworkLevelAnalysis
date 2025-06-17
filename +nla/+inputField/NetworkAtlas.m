classdef NetworkAtlas < nla.inputField.InputField
    %NETWORKATLAS Network atlas, contains network + ROI details
    properties (Constant)
        name = 'net_atlas'
        disp_name = 'Network atlas';
    end
    
    properties
        net_atlas = false
    end
    
    properties (Access = protected)
        button = false
        button_view_net_atlas = false
        checkbox_surface_parcels = false
        label = false
        inflation_label = false
        inflation_dropdown = false
        UIParent = []
    end
    
    methods
        function obj = NetworkAtlas()
            obj.satisfied = false;
        end
        
        function [w, h] = draw(obj, x, y, parent, fig)
            import nla.inputField.LABEL_GAP nla.inputField.LABEL_H nla.inputField.widthOfString
            import nla.gfx.MeshType

            obj.fig = fig;
            obj.UIParent = parent;
            
            label_gap = LABEL_GAP;
            h = LABEL_H;
            
            %% Create label
            if ~isgraphics(obj.label)
                obj.label = uilabel(parent);
            end
            obj.label.Text = 'Network atlas:';
            label_w = widthOfString(obj.label.Text, LABEL_H);
            obj.label.HorizontalAlignment = 'left';
            obj.label.Position = [x, y - LABEL_H, label_w + label_gap, LABEL_H];
            
            %% Create button
            if ~isgraphics(obj.button)
                obj.button = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.buttonClickedCallback());
            end
            button_w = 100;
            obj.button.Position = [x + label_w + label_gap, y - LABEL_H, button_w, LABEL_H];
            
            %% Mesh inflation selector
            if ~isgraphics(obj.inflation_label)
                obj.inflation_label = uilabel(parent);
                obj.inflation_label.HorizontalAlignment = 'right';
                obj.inflation_label.Text = 'Inflation: ';
            end
            inflation_label_w = widthOfString(obj.inflation_label.Text, LABEL_H);
            obj.inflation_label.Position = [0, y - LABEL_H, inflation_label_w, LABEL_H];

            inflation_dropdown_w = 55;
            if ~isgraphics(obj.inflation_dropdown)
                obj.inflation_dropdown = uidropdown(parent);
                obj.inflation_dropdown.Items = ["Std", "Inf", "VInf"];
                obj.inflation_dropdown.ItemsData = {MeshType.STD, MeshType.INF, MeshType.VINF};
            end
            obj.inflation_dropdown.Position = [0, y - LABEL_H, inflation_dropdown_w, LABEL_H];
            
            %% 'View as surface parcel' checkbox
            checkbox_surface_parcels_w = 108;
            if ~isgraphics(obj.checkbox_surface_parcels)
                obj.checkbox_surface_parcels = uicheckbox(parent);
                obj.checkbox_surface_parcels.Text = ' Surface parcels';
            end
            obj.checkbox_surface_parcels.Position = [0, y - LABEL_H, checkbox_surface_parcels_w, LABEL_H];
            
            %% Create view button
            if ~isgraphics(obj.button_view_net_atlas)
                obj.button_view_net_atlas = uibutton(parent, 'push', 'ButtonPushedFcn',...
                @(h,e)obj.buttonViewNetAtlasClickedCallback());
            end
            button_view_net_atlas_w = 45;
            obj.button_view_net_atlas.Text = 'View';
            obj.button_view_net_atlas.Position = [0, y - LABEL_H, button_view_net_atlas_w, LABEL_H];
            
            w = label_w + label_gap + button_w + label_gap + checkbox_surface_parcels_w + label_gap +...
                button_view_net_atlas_w;
        end
        
        function undraw(obj)
            
            if isgraphics(obj.button)
                delete(obj.button)
            end
            if isgraphics(obj.checkbox_surface_parcels)
                delete(obj.checkbox_surface_parcels)
            end
            if isgraphics(obj.button_view_net_atlas)
                delete(obj.button_view_net_atlas)
            end
            if isgraphics(obj.label)
                delete(obj.label)
            end
            if isgraphics(obj.inflation_label)
                delete(obj.inflation_label)
            end
            if isgraphics(obj.inflation_dropdown)
                delete(obj.inflation_dropdown)
            end
        end
        
        function read(obj, input_struct)
            
            obj.loadField(input_struct, 'net_atlas');
            
            if isfield(input_struct, 'surface_parcels')
                obj.checkbox_surface_parcels.Value = input_struct.surface_parcels;
            else
                obj.checkbox_surface_parcels.Value = false;
            end
            
            obj.update();
        end
        
        function [input_struct, error] = store(obj, input_struct)
            input_struct.net_atlas = obj.net_atlas;
            input_struct.surface_parcels = obj.checkbox_surface_parcels.Value;
            error = false;
        end
    end
    
    methods (Access = protected)
        function buttonClickedCallback(obj, ~)
            [file, path, idx] = uigetfile({'*.mat', 'Network Atlas (*.mat)'}, 'Select Network Atlas');
            if idx ~= 0
                % Load file to net_atlas, depending on the filetype. Right now
                % it only supports .mat network atlases but if another file
                % type were added, it would be handled under idx == 2 and so on
                if idx == 1
                    prog = uiprogressdlg(obj.fig, 'Title', 'Loading network atlas', 'Message',...
                        sprintf('Loading %s', file), 'Indeterminate', true);
                    drawnow;
                    
                    try
                        obj.net_atlas = nla.NetworkAtlas([path file]);
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
        
        function buttonViewNetAtlasClickedCallback(obj)
            
            prog = uiprogressdlg(obj.fig, 'Title', 'Generating visualization', 'Message',...
                'Generating net atlas visualization', 'Indeterminate', true);
            drawnow;
            
            mesh_inf = obj.inflation_dropdown.Value;
            
            if obj.checkbox_surface_parcels.Value &&...
                ~islogical(obj.net_atlas.parcels) &&...
                size(obj.net_atlas.parcels.ctx_l, 1) == size(obj.net_atlas.anat.hemi_l.nodes, 1) &&...
                size(obj.net_atlas.parcels.ctx_r, 1) == size(obj.net_atlas.anat.hemi_r.nodes, 1)
                
                nla.gfx.drawNetworkROIs(obj.net_atlas, mesh_inf, 1, 4, true);
            else
                nla.gfx.drawNetworkROIs(obj.net_atlas, mesh_inf, 0.8, 4, false);
            end
            
            if ispc
                nla.gfx.moveFigToParentUILocation(gcf, obj.UIParent);
            end
            close(prog);
            drawnow();
        end
        
        function update(obj)
            import nla.inputField.widthOfString nla.inputField.LABEL_GAP nla.inputField.LABEL_H

            if islogical(obj.net_atlas)
                obj.satisfied = false;
                obj.button.Text = 'Select';
                obj.button_view_net_atlas.Enable = false;
                obj.checkbox_surface_parcels.Enable = false;
                obj.checkbox_surface_parcels.Value = false;
            else
                obj.satisfied = true;
                obj.button.Text = obj.net_atlas.name;
                obj.button_view_net_atlas.Enable = true;
                if ~islogical(obj.net_atlas.parcels)
                    obj.checkbox_surface_parcels.Enable = true;
                else
                    obj.checkbox_surface_parcels.Enable = false;
                    obj.checkbox_surface_parcels.Value = false;
                end
            end
            % Instead of changing the width of the button and making the line unusable, use a tooltip
            % obj.button.Position(3) = widthOfString(obj.button.Text, LABEL_H) + widthOfString('  ', LABEL_H + LABEL_GAP);            
            obj.button.Tooltip = obj.button.Text;
            
            obj.inflation_label.Position(1) = obj.button.Position(1) + obj.button.Position(3) + LABEL_GAP;
            obj.inflation_dropdown.Position(1) = obj.button.Position(1) + obj.button.Position(3) + LABEL_GAP +...
                obj.inflation_label.Position(3);
            
            obj.checkbox_surface_parcels.Position(1) = obj.button.Position(1) + obj.button.Position(3) + LABEL_GAP +...
                obj.inflation_label.Position(3) + obj.inflation_dropdown.Position(3) + LABEL_GAP;
            obj.button_view_net_atlas.Position(1) = obj.button.Position(1) + obj.button.Position(3) + LABEL_GAP +...
                obj.inflation_label.Position(3) + obj.inflation_dropdown.Position(3) + LABEL_GAP +...
                obj.checkbox_surface_parcels.Position(3) + LABEL_GAP;
        end
    end
end

