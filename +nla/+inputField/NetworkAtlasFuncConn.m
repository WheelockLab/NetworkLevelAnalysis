classdef NetworkAtlasFuncConn < nla.inputField.InputField
    %NETWORKATLAS Network atlas, contains network + ROI details
    properties (Constant)
        name = 'net_atlas'
        disp_name = 'Network atlas/Functional connectivity';
    end
    
    properties
        net_atlas = false
        func_conn = false
        func_conn_unordered = false
    end
    
    properties (Access = protected)
        button = false
        button_view_net_atlas = false
        checkbox_surface_parcels = false
        button2 = false
        button_view_fc_avg = false
        label = false
        label2 = false
        inflation_label = false
        inflation_dropdown = false
    end
    
    methods
        function obj = NetworkAtlasFuncConn()
            obj.satisfied = false;
        end
        
        function [w, h] = draw(obj, x, y, parent, fig)
            import nla.inputField.LABEL_GAP nla.inputField.LABEL_H
            import nla.gfx.MeshType

            obj.fig = fig;
            
            label_gap = LABEL_GAP;
            h = LABEL_H * 2 + label_gap;
            
            %% NETWORK ATLAS

            % Create label
            if ~isgraphics(obj.label)
                obj.label = uilabel(parent);
            end
            obj.label.Text = 'Network atlas:';
            label_w = nla.inputField.widthOfString(obj.label.Text, LABEL_H);
            obj.label.HorizontalAlignment = 'left';
            obj.label.Position = [x, y - LABEL_H, label_w + label_gap, LABEL_H];
            
            % Create button
            if ~isgraphics(obj.button)
                obj.button = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.buttonClickedCallback());
            end
            button_w = 100;
            obj.button.Position = [x + label_w + label_gap, y - LABEL_H, button_w, LABEL_H];
            
            % Mesh inflation selector
            if ~isgraphics(obj.inflation_label)
                obj.inflation_label = uilabel(parent);
                obj.inflation_label.HorizontalAlignment = 'right';
                obj.inflation_label.Text = 'Inflation: ';
            end
            inflation_label_w = nla.inputField.widthOfString(obj.inflation_label.Text, LABEL_H);
            obj.inflation_label.Position = [0, y - LABEL_H, inflation_label_w, LABEL_H];

            inflation_dropdown_w = 55;
            if ~isgraphics(obj.inflation_dropdown)
                obj.inflation_dropdown = uidropdown(parent);
                obj.inflation_dropdown.Items = ["Std", "Inf", "VInf"];
                obj.inflation_dropdown.ItemsData = {MeshType.STD, MeshType.INF, MeshType.VINF};
            end
            obj.inflation_dropdown.Position = [0, y - LABEL_H, inflation_dropdown_w, LABEL_H];
            
            % 'View as surface parcel' checkbox
            checkbox_surface_parcels_w = 108;
            if ~isgraphics(obj.checkbox_surface_parcels)
                obj.checkbox_surface_parcels = uicheckbox(parent);
                obj.checkbox_surface_parcels.Text = ' Surface parcels';
            end
            obj.checkbox_surface_parcels.Position = [0, y - LABEL_H, checkbox_surface_parcels_w, LABEL_H];
            
            % Create view button
            if ~isgraphics(obj.button_view_net_atlas)
                obj.button_view_net_atlas = uibutton(parent, 'push', 'ButtonPushedFcn',...
                    @(h,e)obj.buttonViewNetAtlasClickedCallback());
            end
            button_view_net_atlas_w = 45;
            obj.button_view_net_atlas.Text = 'View';
            obj.button_view_net_atlas.Position = [0, y - LABEL_H, button_view_net_atlas_w, LABEL_H];
            
            w = label_w + label_gap + button_w + label_gap + checkbox_surface_parcels_w + label_gap + button_view_net_atlas_w;
            %%

            %% FUNCTIONAL CONNECTIVITY
            % Create label2
            if ~isgraphics(obj.label2)
                obj.label2 = uilabel(parent);
            end
            obj.label2.Text = 'Functional connectivity:';
            label2_w = nla.inputField.widthOfString(obj.label2.Text, LABEL_H);
            obj.label2.HorizontalAlignment = 'left';
            obj.label2.Position = [x, y - h, label2_w + label_gap, LABEL_H];
            
            % Create button2
            if ~isgraphics(obj.button2)
                obj.button2 = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.button2ClickedCallback());
            end
            button2_w = 100;
            obj.button2.Position = [x + label2_w + label_gap, y - h, button2_w, LABEL_H];
            
            % Create view button
            if ~isgraphics(obj.button_view_fc_avg)
                obj.button_view_fc_avg = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.buttonViewFCAvgClickedCallback());
            end
            button_view_fc_avg_w = 45;
            obj.button_view_fc_avg.Text = 'View';
            obj.button_view_fc_avg.Position = [x + label2_w + label_gap + button2_w + label_gap, y - h,...
                button_view_fc_avg_w, LABEL_H];
            
            w2 = label2_w + label_gap + button2_w + label_gap + button_view_fc_avg_w;
            w = max(w, w2);
            %%
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
            if isgraphics(obj.button2)
                delete(obj.button2)
            end
            if isgraphics(obj.button_view_fc_avg)
                delete(obj.button_view_fc_avg)
            end
            if isgraphics(obj.label)
                delete(obj.label)
            end
            if isgraphics(obj.label2)
                delete(obj.label2)
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
            obj.loadField(input_struct, 'func_conn');
            obj.loadField(input_struct, 'func_conn_unordered');
            
            if isfield(input_struct, 'surface_parcels')
                obj.checkbox_surface_parcels.Value = input_struct.surface_parcels;
            else
                obj.checkbox_surface_parcels.Value = false;
            end
            
            obj.update();
        end
        
        function [input_struct, error] = store(obj, input_struct)
            
            input_struct.net_atlas = obj.net_atlas;
            input_struct.func_conn_unordered = obj.func_conn_unordered;
            input_struct.func_conn = obj.func_conn;
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
        
        function button2ClickedCallback(obj, ~)
            [file, path, idx] = uigetfile(...
                {'*.mat', 'MATLAB File (*.mat)'; '*.csv', 'Comma-separated Values (*.csv)'; '*.txt', 'Text file (*.txt)'},...
                'Select Functional Connectivity Matrix', 'MultiSelect', 'on'...
            );
            text_file = file;
            if iscell(file)
                text_file = file{1};
            end
            prog = uiprogressdlg(obj.fig, 'Title', 'Loading functional connectivity data', 'Message',...
                    sprintf('Loading %s', text_file), 'Indeterminate', true);
            drawnow;

            fc_unordered = false;
            if idx == 1        
                fc_data = load([path file]);
            else
                if iscell(file)
                    fc_data = readmatrix([path file{1}]);
                    for current_file = 2:numel(file)
                        fc_data(:,:,current_file) = readmatrix([path file{current_file}]);
                    end
                else
                    fc_data = readmatrix([path file]);
                    fc_data_size = size(fc_data);
                    if numel(fc_data_size) == 2 && fc_data_size(1) ~= fc_data_size(2)
                        greater_dimension = fc_data_size(2);
                        lesser_dimension = fc_data_size(1);
                        if fc_data_size(1) > fc_data_size(2)
                            greater_dimension = fc_data_size(1);
                            lesser_dimension = fc_data_size(2);
                        end
                        third_dimension = greater_dimension / lesser_dimension;
                        fc_data = reshape(fc_data, [lesser_dimension, lesser_dimension, third_dimension]);
                    end
                end
            end

            if isnumeric(fc_data)
                fc_unordered = fc_data;
            elseif isstruct(fc_data)
                if isfield(fc_data, 'functional_connectivity')
                    fc_unordered = fc_data.functional_connectivity;
                elseif isfield(fc_data, 'func_conn')
                    fc_unordered = fc_data.func_conn;
                elseif isfield(fc_data, 'fc')
                    fc_unordered = fc_data.fc;
                else
                    fn = fieldnames(fc_data);
                    if numel(fn) == 1
                        fname = fn{1};
                        if isnumeric(fc_data.(fname))
                            fc_unordered = fc_data.(fname);
                        end
                    end
                end
            end

            % functional connectivity matrix (not ordered/trimmed according to network atlas yet)
            if ~islogical(fc_unordered)
                obj.func_conn_unordered = double(fc_unordered);
                
                %% Transform R-values to Z-scores
                % If this condition isn't true, it cannot be R values
                % If it is true, it is almost certainly R values but might not be
                if all(abs(obj.func_conn_unordered(:)) <= 1)
                    sel = uiconfirm(obj.fig, sprintf('Fisher Z transform functional connectivity data?\n(If you have provided R-values)'), 'Fisher Z transform?');
                    if strcmp(sel, 'Ok')
                        obj.func_conn_unordered = nla.fisherR2Z(obj.func_conn_unordered);
                    end
                end
                obj.update();
            else
                uialert(obj.fig, sprintf('Could not load functional connectivity matrix from %s', file), 'Invalid functional connectivity file');
            end
            close(prog);
        end
        
        function buttonViewNetAtlasClickedCallback(obj)
            
            prog = uiprogressdlg(obj.fig, 'Title', 'Generating visualization', 'Message', 'Generating net atlas visualization', 'Indeterminate', true);
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
            
            close(prog);
            drawnow();
        end
        
        function buttonViewFCAvgClickedCallback(obj)
            
            prog = uiprogressdlg(obj.fig, 'Title', 'Generating figure', 'Message', 'Generating FC average figure',...
                'Indeterminate', true);
            drawnow;
            
            %% Visualize average functional connectivity values
            fc_avg = copy(obj.func_conn);
            fc_avg.v = mean(fc_avg.v, 2);
            fig_l = nla.gfx.createFigure();
            matrix_plot = nla.gfx.plots.MatrixPlot(fig_l, 'FC Average (Fisher Z(R))', fc_avg, obj.net_atlas.nets,...
                nla.gfx.FigSize.LARGE);
            fig_l.Position(3) = matrix_plot.image_dimensions("image_width");
            fig_l.Position(4) = matrix_plot.image_dimensions("image_height");
            matrix_plot.displayImage();
            
            close(prog);
            drawnow();
        end
        
        function updateFuncConn(obj)
            
            obj.func_conn = false;
            obj.satisfied = false;
            if ~islogical(obj.net_atlas) && ~islogical(obj.func_conn_unordered)
                dims = size(obj.func_conn_unordered);
                if numel(dims) == 3 && dims(1) == dims(2) && dims(1) == obj.net_atlas.numROIs
                    obj.func_conn = nla.TriMatrix(obj.func_conn_unordered(obj.net_atlas.ROI_order, obj.net_atlas.ROI_order, :));
                    obj.satisfied = true;
                else
                    uialert(obj.fig, 'Network atlas and functional connectivity matrix do not match!',...
                        'Mismatched input files', 'Icon', 'warning');
                end
            end
        end
        
        function update(obj)
            import nla.inputField.widthOfString nla.inputField.LABEL_H nla.inputField.LABEL_GAP            

            obj.updateFuncConn();
            
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
            
            if islogical(obj.func_conn_unordered)
                obj.button2.Text = 'Select';
            else
                nstr = join(string(size(obj.func_conn_unordered)), 'x');
                obj.button2.Text = [sprintf('Matrix (%s)', nstr)];
            end
            obj.button2.Position(3) = widthOfString(obj.button2.Text, LABEL_H) + widthOfString('  ', LABEL_H + LABEL_GAP);
            
            if ~islogical(obj.net_atlas) && ~islogical(obj.func_conn_unordered)
                obj.button_view_fc_avg.Enable = true;
            else
                obj.button_view_fc_avg.Enable = false;
            end
            obj.button_view_fc_avg.Position(1) = obj.button2.Position(1) + LABEL_GAP + obj.button2.Position(3);
        end
    end
end

