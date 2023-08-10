function varargout = run(varargin)
    %RUN Run mex function, compiling if necessary
    import nla.* % required due to matlab package system quirks
    
    if nargin > 0
        func_name = varargin{1};
        if (ischar(func_name) || isstring(func_name))
            % hash the source file to check if we have an up-to-date binary
            % already compiled or not
            func_src_path = [findRootPath() '+nla/+mex/+src/' char(func_name) '.c'];
            func_src_hash = char(helpers.file.hash(func_src_path));
            
            func_name_hashed = [func_name '_' func_src_hash];
            bin_path = [findRootPath() '+nla/+mex/+bin/'];
            func_bin_path = [bin_path func_name_hashed];
            
            %% compile MEX file if necessary
            if ~exist(func_bin_path, 'file')
                fprintf("Could not fine binary for MEX function '%s' (source hash %s). Compiling...\n", func_name, func_src_hash);
                
                % copy source file to build path and rename
                build_path = [findRootPath() '+nla/+mex/+bin/' char(func_name_hashed) '.c'];
                fprintf("Copying source: %s\nto build location: %s\n", func_src_path, build_path);
                copyfile(func_src_path, build_path);
                
                % compile executable
                mex('-R2018a', '-outdir', bin_path, build_path);
                
                % delete intermediary build file
                delete(build_path);
                
                % delete outdated binaries of the same function
                matching = helpers.file.findMatching([bin_path func_name '_*']);
                if size(matching, 1) > 0
                    for i = [1:size(matching, 1)]
                        outdated_bin_path = matching(i);
                        if strlength(outdated_bin_path) > 0
                            fname_split = split(outdated_bin_path, '.');
                            if ~strcmp(fname_split(1), func_bin_path)
                                fprintf("Deleting outdated binary at path: '%s'\n", outdated_bin_path);
                                delete(outdated_bin_path);
                            end
                        end
                    end
                end
            end
            
            %% create function handle
            % does not error with invalid function names
            func_name_full = ['mex.bin.' func_name_hashed];
            func_handle = str2func(func_name_full);
            
            %% run function and return output
            % format input arguments
            if nargin > 1
                args_in = varargin{2:end};
            else
                args_in = {};
            end
            
            % run and collect output if necessary
            if nargout
                varargout = func_handle(args_in);
            else
                func_handle(args_in);
            end
        else
            mex.usageError('func_name must be a character array or string')
        end
    else
        mex.usageError('Not enough arguments')
    end
end

