classdef EdgeLevelMatrix < nla.inputField.InputField
    properties
        name
        disp_name
        dimensions
        matrix = false
        matrix_ordered = false
    end
    
    properties (Access = protected)
        label = false
        select_file_button = false
    end
    
    methods
        function obj = EdgeLevelMatrix(name, disp_name, dimensions)
            import nla.* % required due to matlab package system quirks
            obj.name = name;
            obj.disp_name = disp_name;
            obj.dimensions = dimensions;
            obj.satisfied = false;
        end
        
        function [w, h] = draw(obj, x, y, parent, fig)
            import nla.* % required due to matlab package system quirks
            
            obj.fig = fig;
            
            h = inputField.LABEL_H;
            label_gap = inputField.LABEL_GAP;
            
            %% Create label
            if ~isgraphics(obj.label)
                obj.label = uilabel(parent);
            end
            obj.label.Text = obj.disp_name;
            label_w = inputField.widthOfString(obj.label.Text, h);
            obj.label.HorizontalAlignment = 'left';
            obj.label.Position = [x, y - h, label_w + label_gap, h];
            
            %% Create button
            if ~isgraphics(obj.select_file_button)
                obj.select_file_button = uibutton(parent, 'push', 'ButtonPushedFcn', @(h,e)obj.selectFile());
            end
            button_w = 100;
            obj.select_file_button.Position = [x + label_w + label_gap, y - h, button_w, h];
            
            w = label_w + label_gap + button_w;
        end
        
        function undraw(obj)
            import nla.* % required due to matlab package system quirks
            if isgraphics(obj.label)
                delete(obj.label)
            end
            if isgraphics(obj.select_file_button)
                delete(obj.select_file_button)
            end
        end
        
        function read(obj, input_struct)
            import nla.* % required due to matlab package system quirks
            if isfield(input_struct, [obj.name '_unordered'])
                obj.matrix = input_struct.([obj.name '_unordered']);
            else
                obj.matrix = false;
            end
            
            if isfield(input_struct, obj.name)
                obj.matrix_ordered = input_struct.(obj.name);
            else
                obj.matrix_ordered = false;
            end
            
            obj.update();
        end
        
        function [input_struct, error] = store(obj, input_struct)
            import nla.* % required due to matlab package system quirks
            
            if ~islogical(obj.matrix)
                input_struct.([obj.name '_unordered']) = obj.matrix;
            end
            
            error = false;
            if isfield(input_struct, 'net_atlas') && isfield(input_struct, 'perm_count') && ~islogical(input_struct.net_atlas) && ~islogical(obj.matrix)
                dims = size(obj.matrix);
                
                desired_dims = obj.substituteDims(obj.dimensions, input_struct.net_atlas.numROIs, nla.helpers.triNum(input_struct.net_atlas.numROIs - 1), input_struct.perm_count);
                if numel(dims) == numel(desired_dims) && all(dims == desired_dims)
                    if obj.dimensions(1) == inputField.DimensionType.NROIPAIRS
                        obj.matrix_ordered = TriMatrix(input_struct.net_atlas.numROIs);
                        obj.matrix_ordered.v = obj.matrix;
                    else
                        obj.matrix_ordered = TriMatrix(input_struct.net_atlas.numROIs);
                        obj.matrix_ordered.v = obj.matrix;
                    end
                    
                    input_struct.(obj.name) = obj.matrix_ordered;
                else
                    error = sprintf('Matrix does not match network atlas/permutation dimensions (should be %s, is %s)!', join(string(desired_dims), "x"), join(string(dims), "x"));
                end
            else
                error = 'Something has gone badly wrong with inputField.EdgeLevelMatrix, please report this on the NLA Github or contact an author';
            end
        end
        
        function selectFile(obj, ~)
            import nla.* % required due to matlab package system quirks
            [fname, path, idx] = uigetfile({'*.mat', sprintf('Matrix (%s) (*.mat)', obj.dimsAsString())}, 'Select Input Matrix');
            if idx == 1
                prog = uiprogressdlg(obj.fig, 'Title', sprintf('Loading %s', obj.disp_name), 'Message', sprintf('Loading %s', fname), 'Indeterminate', true);
                drawnow;
                    
                file_struct = load([path fname]);
                final_matrix = false;
                if isnumeric(file_struct)
                    final_matrix = fc_data;
                elseif isstruct(file_struct)
                    fn = fieldnames(file_struct);
                    if numel(fn) == 1
                        fname = fn{1};
                        if isnumeric(file_struct.(fname))
                            final_matrix = file_struct.(fname);
                        end
                    end
                end

                % functional connectivity matrix (not ordered/trimmed according to network atlas yet)
                if ~islogical(final_matrix)
                    obj.matrix = double(final_matrix);
                    
                    obj.update();
                    close(prog);
                else
                    close(prog);
                    uialert(obj.fig, sprintf('Could not load %s matrix from %s', obj.disp_name, fname), 'Invalid file');
                end
            end
        end
        
        function update(obj)
            import nla.* % required due to matlab package system quirks
            if islogical(obj.matrix)
                obj.select_file_button.Text = 'Select';
            else
                obj.satisfied = true;
                
                nstr = join(string(size(obj.matrix)), 'x');
                obj.select_file_button.Text = [sprintf('Matrix (%s)', nstr)];
            end
            obj.select_file_button.Position(3) = inputField.widthOfString(obj.select_file_button.Text, inputField.LABEL_H) + inputField.widthOfString('  ', inputField.LABEL_H + inputField.LABEL_GAP);
        end
        
        function dims = substituteDims(~, input_dims, nrois, nroipairs, nperms)
            import nla.* % required due to matlab package system quirks
            for i = [1:numel(input_dims)]
                dim = input_dims(i);
                if dim == inputField.DimensionType.NROIS
                    dims(i) = nrois;
                elseif dim == inputField.DimensionType.NROIPAIRS
                    dims(i) = nroipairs;
                elseif dim == inputField.DimensionType.NPERMS
                    dims(i) = nperms;
                else
                    if isstring(nrois)
                        dims(i) = string(dim);
                    else
                        dims(i) = dim;
                    end
                end
            end
        end
        
        function str = dimsAsString(obj)
            str = join(obj.substituteDims(obj.dimensions, "nrois", "nroipairs", "nperms"), " x ");
        end
    end
end

